$:.unshift File.dirname(__FILE__)

require 'hathifiles_db/logger'
require "hathifiles_db/version"
require 'hathifiles_db/fill_ht_constant_codes'
require 'hathifiles_db/schema'
require 'oga'
require 'rest-client'
require 'hathifiles_db/sourceline'
require 'hathifiles_db/update_file_set'
require 'dry-auto_inject'
require 'logger'
require 'hathifiles_db/fullfile_import'

class HathifilesDB

  include Inject["db"]

  URL = 'https://www.hathitrust.org/hathifiles'


  # Some accessors for the stuff we care about
  def bookkeeping
    @bookkeeping ||= HathifilesDB::Schema::Bookkeeping.new
  end

  def htid
    @htid ||= HathifilesDB::Schema::HTID.new
  end

  def stdid
    @stdid ||= HathifilesDB::Schema::StdID.new
  end

  def update_files
    @update_files ||= UpdateFileSet.new
  end

  def schema
    @schema ||= HathifilesDB::Schema.new
  end


  # Try to submit a batch of main table (:htid) data
  # If it succeeds, it means they were all new.
  # If it fails, try the next smaller batch size.
  # Finally, we'll get down to a batch that we'll just
  # re-send in upsert mode.
  def send_in_batches_of(sizes, mains)
    db.transaction do
      if sizes.empty?
        htid.replace(mains)
      else
        mains.each_slice(sizes[0]) do |m|
          begin
            htid.add(m)
          rescue Sequel::UniqueConstraintViolation => e # try the next size down
            send_in_batches_of(sizes[1..-1], m)
          end
        end
      end
    end
  end


  # What size batches are we going to try to send to the database?
  SLICE_SIZES   = [100]
  LINES_TO_READ = 1000

  # Cycle through the downloaded file and submit batches of
  # data.
  def update_from_file_obj(file_obj)
    total = 0
    file_obj.each_slice(LINES_TO_READ) do |lines|
      total       += lines.size
      insertables = lines.map {|x| HathifilesDB::SourceLine.new(x)}
      htids       = insertables.map(&:id)
      mains       = insertables.map(&:main_hash)
      identifiers = insertables.inject([]) do |acc, i|
        acc.concat i.isbn
        acc.concat i.issn
        acc.concat i.oclc
        acc.concat i.lccn
        acc
      end

      send_in_batches_of(SLICE_SIZES, mains)

      stdid.delete_for_ids(htids)
      stdid.add(identifiers)
      LOG.info "  #{total} so far in this file" if (total > 0) and (total % 5_000 == 0)
    end
    total
  end

  def truncate_tables
    LOG.info "Truncating db tables"
    schema.truncate
  end

  def drop_even_main_index_for_full
    LOG.info "Dropping the uniq htid index"
    begin
      db.alter_table(:htid) do
        drop_index :htid
      end
    rescue Sequel::DatabaseError => e
      if e.message =~ /no such index/
        # do nothing; we're fine
      else
        raise e
      end
    end
  end

  def add_back_main_index
    LOG.info "Adding back main index"
    begin
      db.alter_table(:htid) do
        add_index :htid, unique: true
      end
    rescue => e # Index already existed
    end

  end

  def should_drop_indexes?
    update_files.full? # or update_files.large?
  end


  def drop_indexes_if_necessary
    if should_drop_indexes?
      LOG.info "Lots to do. Dropping indexes to make it faster"
      schema.drop_indexes
    end
  end

  def add_indexes_if_necessary
    if should_drop_indexes?
      LOG.info "Adding indexes back in"
      schema.add_indexes
    end
  end


  def update_full
    schema.drop_indexes
    drop_even_main_index_for_full
    LOG.info "Pulling down full file, dumping to file, and loading with bulk import"
    HathifilesDB::FullFileImport.new.transform_and_import(update_files.full_file)
    LOG.info "Done with full file dump and bulk import"
  end

  # Figure out what to update, and update it.
  def update
    if update_files.empty?
      LOG.info "Nothing to do. No update files."
      return
    end
    LOG.info "#{update_files.count} files to load"


    if update_files.full?
      LOG.info "Doing a full index"
      unless ENV['DEBUG']
        truncate_tables
        update_full
      end
    else
      drop_indexes_if_necessary
    end


    update_files.each_incremental_update_file do |file|
      added = update_from_file_obj(file)
      LOG.info "Indexed #{added} lines"
    end

    add_indexes_if_necessary

    mrd = update_files.most_recent_date
    bookkeeping.last_update = mrd
    LOG.info "Last update date set to #{mrd}"
  end


end


$:.unshift File.dirname(__FILE__)

require "hathifiles_db/version"
require 'hathifiles_db/fill_ht_constants_codes'
require 'hathifiles_db/schema'
require 'oga'
require 'rest-client'
require 'hathifiles_db/sourceline'
require 'hathifiles_db/update_file_set'
require 'dry-auto_inject'
require 'logger'

class HathifilesDB

  include Inject["db"]

  LOG = Logger.new(STDERR)

  URL = 'https://www.hathitrust.org/hathifiles'


  # Some accessors for the stuff we care about
  def bookkeeping
    @bookkeeping ||= HathifilesDB::Schema::Bookkeeping.new
  end

  def htid
    @htid ||= HathifilesDB::Schema::HTID.new
  end

  def stdid
    @stdid ||=  HathifilesDB::Schema::StdID.new
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
  SLICE_SIZES = [1000, 100]
  LINES_TO_READ = 1000

  # Cycle through the downloaded file and submit batches of
  # data.
  def update_from_file_obj(file_obj)
    total       = 0
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
      LOG.info "#{total} so far in this file" if (total > 0) and (total % 20_000 == 0)
    end
    return total
  end

  # Figure out what to update, and update it.
  def update
    if update_files.empty?
      return
    end

    if update_files.full?
      LOG.info "Doing a full reindex. Truncating db tables"
      schema.truncate
    end

    update_files.drop_indexes_if_necessary
    update_files.each do |file|
      added = update_from_file_obj(file)
      LOG.info "Indexed #{added} lines"
    end
    update_files.add_indexes_if_necessary
    bookkeeping.last_update = update_files.most_recent_date
  end
  

end

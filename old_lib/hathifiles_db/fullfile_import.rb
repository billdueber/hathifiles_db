# Doing a "normal" set of inserts into the databases with this much
# data just dies on my machine, even after taking out all the indexes
# and everything (e.g., I got to 2.8m records overnight).
#
# So, we'll try to do a dump to a tab-delimited file and then
# do a bulk import for just the full file.

require 'sequel'
require 'tempfile'
require_relative 'sourceline'
require 'csv'
require_relative "schema/bookkeeping"

class HathifilesDB
  class FullFileImport
    include Inject["db"]

    attr_reader :inputfile, :htidfile, :stdidfile

    def is_mysql?
      db.database_type == :mysql or db.database_type == :mysql2
    end

    def is_sqlite?
      db.database_type == :sqlite
    end


    # SQLITE/MySQL transform
    def mysql_transform(sl)
      dt = sl.main_hash[:last_update]

    end


    # Download the full file
    HTID_CSV_NAME   = "/tmp/htidfile.csv"
    HTID_STDID_NAME = "/tmp/stdidfile.csv"

    def create_csvs(fh)
      return if File.exist?(HTID_CSV_NAME)
      inputfile.each_with_index do |line, i|
        sl = SourceLine.new(line)
        begin
          sl.main_hash[:last_update] = sl.main_hash[:last_update].to_s[0..18] if is_mysql?
        rescue NoMethodError => e
          LOG.error "NoMethodError for attempt to update `last_update` for #{sl.id} / #{sl.main_hash['title']} "
        end


      end
    end

    def fix_mysql_date(dt)
      dt.to_s[0..18]
    end

    # We need to get the filehandle for the full hathifile
    # and create two temp files: one for the htid table,
    # and one for the stdid table
    def transform_and_import (filehandle, file_date, tmpdir = ENV['HATHIFILE_TEMPDIR'] || Dir.tmpdir)
      @inputfile           = filehandle
      @file_date = file_date

      # @htidfile  = Tempfile.new('htid', tmpdir, encoding: 'utf-8')
      # @stdidfile = Tempfile.new('htid', tmpdir, encoding: 'utf-8')

      @htid_table_columns  = db[:htid].columns
      @stdid_table_columns = [:htid, :type, :value]

      LOG.info "Transform/normalize full-file to local .csv files (in #{tmpdir}) in prep for bulk import"

      @htid_path  = File.join(tmpdir, "htidfile_#{@file_date}.csv")
      @stdid_path = File.join(tmpdir, "stdidfile_#{@file_date}.csv")

      if File.exist?(@htid_path)
        LOG.warn "Full-file import using existing CSV files at #{@htid_path} and #{@stdid_path}"
      else
        LOG.info "Beginning transformation. This is slow"
        @htidfile  = CSV.open(@htid_path, 'w:utf-8')
        @stdidfile = CSV.open(@stdid_path, 'w:utf-8')

        inputfile.each_with_index do |line, i|
          sl                         = SourceLine.new(line)
          sl.main_hash[:last_update] = fix_mysql_date(sl.main_hash[:last_update]) if is_mysql?
          dump_to_htid(sl.main_hash)
          dump_to_stdid(sl.stdid)
          LOG.info "...#{i / 1_000_000}M items" if i > 0 and i % 1_000_000 == 0
        end
        @htidfile.close
        @stdidfile.close
      end
      LOG.info "Done. Beginning bulk-import into database"
      push_into_db
    end

    def dump_to_htid(h)
      @htidfile << h.values_at(*@htid_table_columns)
    end

    def dump_to_stdid(arr)
      arr.each do |triple|
        @stdidfile << triple
      end
    end

    def push_into_db
      if is_mysql?
        push_into_mysql
      elsif is_sqlite?
        push_into_sqlite
      else
        raise "Don't know how to bulk-load into db type #{db.database_type}"
      end
      HathifilesDB::Schema::Bookkeeping.new.last_full_file_date = @file_date

    end


    def push_into_sqlite
      dbname = db.uri.gsub(/\A.*?sqlite3?:\/\//, '')
      # system("echo", "-e", ".mode csv\\\\n.import ./htidfile.csv htid")
      IO.popen(["sqlite3", dbname], 'w+:utf-8') do |sqlite_client|
        sqlite_client.puts '.mode csv'
        sqlite_client.puts ".import #{@htid_path}  htid"
        sqlite_client.puts ".import #{@stdid_path} stdid"
        sqlite_client.close_write
      end

    end

    def push_into_mysql
      db.run %Q{LOAD DATA LOCAL INFILE '#{@htid_path}' into table htid
        COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"' LINES TERMINATED BY '\n'}
      db.run %Q{LOAD DATA LOCAL INFILE '#{@stdid_path}' into table stdid
        COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"' LINES TERMINATED BY '\n'}
    end
  end
end



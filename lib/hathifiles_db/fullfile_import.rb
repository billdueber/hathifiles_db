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

    # We need to get the filehandle for the full hathifile
    # and create two temp files: one for the htid table,
    # and one for the stdid table
    def transform_and_import (filehandle, tmpdir = ENV['HATHIFILE_TEMPDIR'] || Dir.tmpdir)
      @inputfile           = filehandle

      # @htidfile  = Tempfile.new('htid', tmpdir, encoding: 'utf-8')
      # @stdidfile = Tempfile.new('htid', tmpdir, encoding: 'utf-8')

      @htid_table_columns  = db[:htid].columns
      @stdid_table_columns = [:htid, :type, :value]

      LOG.info "Transform/normalize fullfile to local .csv file in prep for bulk import"
      if File.exist?('/tmp/htidfile.csv')
        @htid_path  = '/tmp/htidfile.csv'
        @stdid_path = '/tmp/stdidfile.csv'
        LOG.warn "Using existing file at /tmp/htidfile.csv"
      else
        htid_tmp   = Tempfile.new('htid', tmpdir, encoding: 'utf-8')
        @htidfile  = CSV.open(htid_tmp, 'w:utf-8')
        @htid_path = htid_tmp.path

        stdid_tmp   = Tempfile.new('stdid', tmpdir, encoding: 'utf-8')
        @stdidfile  = CSV.open(stdid_tmp, 'w:utf-8')
        @stdid_path = stdid_tmp.path

        inputfile.each_with_index do |line, i|
          sl = SourceLine.new(line)
          begin
            sl.main_hash[:last_update] = sl.main_hash[:last_update].to_s[0..18] if is_mysql?
          rescue NoMethodError => e
            LOG.error "NoMethodError for attempt to update `last_update` for #{sl.id} / #{sl.main_hash['title']} "
          end

          dump_to_htid(sl.main_hash)
          dump_to_stdid(sl.stdid)
          LOG.info "...#{i / 1_000_000}M items" if i > 0 and i % 1_000_000 == 0
        end
        @htidfile.close
        @stdidfile.close
      end
      LOG.info "Done. Bulk importing into database"
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
      db.run %Q{LOAD DATA INFILE '#{@htid_path}' into table htid
        COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"' LINES TERMINATED BY '\n'}
      db.run %Q{LOAD DATA INFILE '#{@stdid_path}' into table stdid
        COLUMNS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"' LINES TERMINATED BY '\n'}
    end
  end
end



require 'hathifiles_db/constants'
module HathifilesDB
  module Schema
    class Base
      include HathifilesDB::Inject["db", "logger"]

      attr_reader :db


      def table_name
        raise "Need to set in subclass"
      end

      def exists?
        db.tables.include? table_name
      end


      def table
        db[table_name]
      end

      def <<(hlines_as_array)
        return if hlines_as_array.empty?
        hlines = if hlines_as_array.first.kind_of? Array
                   hlines_as_array
                 else
                   [hlines_as_array]
                 end
        add_many_hf_lines(hlines)
      end

      def add_many_hf_lines(bunch_of_lines)
        return if bunch_of_lines.empty?
        insertables = bunch_of_lines.map do |hline_as_array|
          hf_line_data(hline_as_array)
        end.flatten(1)


        ids = bunch_of_lines.map(&:first)
        delete_by_id(ids)
        begin
          table.import(columns, insertables, commit_every: bunch_of_lines.size)
        rescue => e
          puts "OOPS: #{table_name}: #{insertables}"
          exit(1)
        end

      end


      def index_columns
        raise "Need to set in subclass"
      end

      def hathifile_tsv_column_indexes
        @hf_column_indexes ||= hathifile_tsv_columns.map {|x| HathifilesDB::Constants::HF_COLUMN_INDEXES[x]}

      end

      def raw_hf_line_data(hathifile_line_as_array)
        hathifile_line_as_array.values_at(*(hathifile_tsv_column_indexes))
      end

      def hf_line_data(hathifile_line_as_array)
        [process(raw_hf_line_data(hathifile_line_as_array))]
      end

      def process(arr)
        arr
      end

      def recreate
        drop_table
        create
        create_indexes
      end

      def drop_table(ignore_dne = true)
        db.drop_table?(table_name)
      end

      def create_table(ignore_dne = true, &blk)
        db.create_table!(table_name, &blk)
      end

      def columns
        db[table_name].columns
      end

      def current_indexes
        db.indexes(table_name).values.map {|x| x[:columns]}
      end


      def create_indexes(columns = self.index_columns)
        columns = columns.map {|x| Array(x)}
        columns = columns - current_indexes
        db.alter_table(table_name) do
          columns.each do |c|
            add_index c
          end
        end
      end


      def drop_indexes(columns = self.current_indexes)
        db.alter_table(table_name) do
          columns.each do |c|
            drop_index c
          end
        end
      end

      # A simple way to delete everything that has one of a set of IDs
      def delete_by_id(ids)
        ids = Array(ids)
        db[table_name].where(id: ids).delete
      end

      def import_tsv(import_path, table_name: self.table_name.to_s)
        if db.uri =~ /sqlite/
          import_tsv_into_sqlite(import_path, table_name: table_name)
        end
      end


      def import_tsv_into_sqlite(import_path, table_name: self.table_name.to_s)
        filename = File.join(ENV['TSVDIR'], import_path)
        dbname   = db.uri.gsub(/\A.*?sqlite3?:\/\//, '')
        IO.popen(["sqlite3", dbname], 'w+:utf-8') do |sqlite_client|
          sqlite_client.puts '.mode tabs'
          sqlite_client.puts ".import #{filename}  #{table_name}"
          sqlite_client.close_write
        end
      end

      def with_fast_sql_flags(&blk)
        with_fast_sqlite_flags &blk
      end

      def with_fast_sqlite_flags
        dbname   = db.uri.gsub(/\A.*?sqlite3?:\/\//, '')
        sqlite_client = Kernel.open("|sqlite3 hf.db", 'w+:utf-8'))

        sqlite_client.puts 'pragma synchronous;'
        old_sync = sqlite_client.gets
        sqlite_client.puts "pragma journal_mode;"
        old_jmode = sqlite_client.gets

        s.puts 'pragma synchronous = 0;'
        s.puts 'pragma journal_mode=WAL;'

        yield

        s.puts "pragma synchronous = #{old_sync}"
        s.puts "pragma journal_mode=#{old_jmode};"
        s.close
      end
    end
  end
end





module HathifilesDB
  module Schema
    class Base
      include HathifilesDB::Inject["db"]

      attr_reader :db



      def table_name
        raise "Need to set in subclass"
      end


      def index_columns
        raise "Need to set in subclass"
      end

      def hathifile_tsv_column_indexes
        @hf_column_indexes ||= hathifile_tsv_columns.map{|x| HathifilesDB::Hathifile::HF_COLUMN_INDEXES[x]}
      end

      def hf_line_data(hathifile_line_as_array)
        hathifile_line_as_array.values_at(*(hathifile_tsv_column_indexes))
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
        columns = columns.map{|x| Array(x)}
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

      def import_tsv(import_path, table_name: self.table_name.to_s)
        if db.uri =~ /sqlite/
          import_csv_into_sqlite(import_path, table_name: table_name)
        end
      end


      def import_csv_into_sqlite(import_path, table_name: self.table_name.to_s)
        dbname = db.uri.gsub(/\A.*?sqlite3?:\/\//, '')
        IO.popen(["sqlite3", dbname], 'w+:utf-8') do |sqlite_client|
          sqlite_client.puts '.mode csv'
          sqlite_client.puts ".import #{import_path}  #{table_name}"
          sqlite_client.close_write
        end
      end

      def import_tsv_into_sqlite(import_path, table_name: self.table_name.to_s)
        dbname = db.uri.gsub(/\A.*?sqlite3?:\/\//, '')
        IO.popen(["sqlite3", dbname], 'w+:utf-8') do |sqlite_client|
          sqlite_client.puts '.mode tabs'
          sqlite_client.puts ".import #{import_path}  #{table_name}"
          sqlite_client.close_write
        end
      end

    end
  end
end



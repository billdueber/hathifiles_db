require 'hathifiles_db/schema/base'

module HathifilesDB
  module Schema
    class Bookkeeping < Base

      def table_name
        :bookkeeping
      end

      def index_columns
        []
      end

      def create
        create_table do
          Number :last_update_YYYYMMDD
        end
        db[table_name].insert(last_update_YYYYMMDD: 0)
      end

      def last_updated
        db[table_name].get(:last_update_YYYYMMDD)
      end

      def update(val)
        db[table_name].update(last_update_YYYYMMDD: val)
      end


    end
  end
end

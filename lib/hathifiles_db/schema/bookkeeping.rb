require 'hathifiles_db/schema'

module HathifilesDB
  module Schema
    class Bookkeeping
      include HathifilesDB::Inject["db"]
      include HathifilesDB::Schema::InstanceMethods

      def table_name
        :bookkeeping
      end

      def create
        create_table do
          Number :last_update_YYYYMMDD
        end
        db[table_name].insert(last_update_YYYYMMDD: 0)
      end






    end
  end
end

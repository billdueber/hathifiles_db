require 'hathifiles_db/schema/htid'
require 'hathifiles_db/schema/stdid'
require 'hathifiles_db/schema/bookkeeping'
require 'hathifiles_db/schema/creation'

class HathifilesDB
  class Schema
    include Inject["db"]

    def create_new_schema
      HathifilesDB::Schema::Creation.new.create_tables
      HathifilesDB::FillHTConstantCodes.new.fill_all
    end

    def drop_indexes
      # quick check to see if there are any there!
      return if db.indexes(:htid).empty?

      [HathifilesDB::Schema::HTID, HathifilesDB::Schema::StdID].each do |klass|
        klass.new.drop_indexes
      end
    end

    def add_indexes
      [HathifilesDB::Schema::HTID, HathifilesDB::Schema::StdID].each do |klass|
        klass.new.add_indexes
      end
    end

    def truncate
      [HathifilesDB::Schema::HTID, HathifilesDB::Schema::StdID].each do |klass|
        klass.new.truncate
      end
    end
  end
end

module HathifilesDB
  module Schema
    module InstanceMethods

      def create_table(&blk)
        db.create_table(table_name, &blk)
      end
    end
  end
end


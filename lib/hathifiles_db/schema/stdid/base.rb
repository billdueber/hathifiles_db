require 'hathifiles_db/schema/base'

module HathifilesDB
  module Schema
    module STDID
      class Base < HathifilesDB::Schema::Base
        def index_columns
          [
            :id,
            :number
          ]
        end



        def create
          create_table do
            String :id
            index :id

            String :number
            index :number
          end
        end
      end
    end
  end
end


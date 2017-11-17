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

        def process_val(val)
          val
        end

        def hf_line_data(hathifile_line_as_array)
          id, vals = *(raw_hf_line_data(hathifile_line_as_array))
          return [] unless vals =~ /[^\s"]/
          multivals = vals.split(/\s*,\s*/).map{|x| process_val(x)}

          multivals.map{|v| [id, v]}
        end

      end
    end
  end
end


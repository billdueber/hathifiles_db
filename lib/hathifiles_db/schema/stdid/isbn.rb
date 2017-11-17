require 'hathifiles_db/schema/stdid/base'
require 'library_stdnums'

module HathifilesDB
  module Schema
    module STDID
      class ISBN < Base
        def table_name
          :isbn
        end

        def hathifile_tsv_columns
          [:id, :isbns]
        end

        def process_val(val)
          StdNum::ISBN.convert_to_13(val)
        end
      end
    end
  end
end

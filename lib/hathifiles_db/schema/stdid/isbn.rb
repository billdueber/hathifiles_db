require 'hathifiles_db/schema/stdid/base'

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
      end
    end
  end
end

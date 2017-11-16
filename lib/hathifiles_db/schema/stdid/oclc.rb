require 'hathifiles_db/schema/stdid/base'
module HathifilesDB
  module Schema
    module STDID
      class OCLC < Base
        def table_name
          :oclc
        end
        def hathifile_tsv_columns
          [:id, :oclcs]
        end
      end
    end
  end
end

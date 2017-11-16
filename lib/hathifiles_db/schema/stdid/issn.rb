require 'hathifiles_db/schema/stdid/base'

module HathifilesDB
  module Schema
    module STDID
      class ISSN < Base
        def table_name
          :issn
        end

        def hathifile_tsv_columns
          [:id, :issns]
        end
      end
    end
  end
end

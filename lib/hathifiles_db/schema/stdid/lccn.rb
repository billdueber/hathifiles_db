require 'hathifiles_db/schema/stdid/base'
module HathifilesDB
  module Schema
    module STDID
      class LCCN < Base
        def table_name
          :lccn
        end

        def hathifile_tsv_columns
          [:id, :lccns]
        end
      end
    end
  end
end


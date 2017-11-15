require 'hathifiles_db/schema/stdid/base'
module HathifilesDB
  module Schema
    module STDID
      class OCLC < Base
        def table_name
          :oclc
        end
      end
    end
  end
end

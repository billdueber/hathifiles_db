require 'hathifiles_db/schema/stdid/base'

module HathifilesDB
  module Schema
    module STDID
      class ISSN < Base
        def table_name
          :issn
        end
      end
    end
  end
end

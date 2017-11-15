require 'hathifiles_db/schema/stdid/base'
module HathifilesDB
  module Schema
    module STDID
      class LCCN < Base
        def table_name
          :lccn
        end
      end
    end
  end
end


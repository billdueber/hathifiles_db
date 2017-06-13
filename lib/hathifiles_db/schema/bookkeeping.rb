require 'sequel'

class HathifilesDB
  class Schema

    class Bookkeeping

      include Inject["db"]

      def table
        @table ||= db[:bookkeeping]
      end


      def truncate
        table.truncate
      end

      # Figure out when update was last run
      def last_update
        @last_update ||= table.select(:value).where(key: 'last_updated').single_value.to_i
      end

      def last_update=(dt)
        table.where(key: 'last_updated').update(value: dt.to_i)
      end

    end


  end
end

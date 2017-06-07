require 'sequel'

class HathifilesDB
  class Schema

    class HTID
      include Inject["db"]

      HTID_INDEXES = [:allow, :rights_code, :record_id, :source_code,
                      :source_record_number, :reason_code, :last_update,
                      :govdoc, :pub_year]

      def table
        @table ||= db[:htid]
      end

      def truncate
        table.truncate
      end

      def add(hashes)
        table.multi_insert(hashes)
      end

      def replace(hashes)
        table.multi_replace(hashes)
      end

      # Doing the load with indexes intact can be slower
      # For a full index, we'll want to drop then add them
      #
      # Basically, drop everything but :htid in the htid table
      def drop_indexes
        db.alter_table(:htid) do
          HTID_INDEXES.each do |i|
            drop_index i
          end
        end
      end

      def add_indexes
        db.alter_table(:htid) do
          HTID_INDEXES.each do |i|
            add_index i
          end
        end
      end



    end
  end
end

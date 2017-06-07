require 'sequel'

class HathifilesDB
  class Schema

    class StdID
      include Inject["db"]


      STDID_INDEXES = [:htid, :type, :value]

      def table
        @table ||= db[:stdid]
      end

      def truncate
        table.truncate
      end

      def delete_for_ids(ids)
        ids = Array(ids)
        table.where(htid: ids).delete
      end

      def add(hashes)
        table.multi_insert(hashes)
      end

      def drop_indexes
        db.alter_table(:stdid) do
          STDID_INDEXES.each do |i|
            drop_index i
          end
        end
      end

      def add_indexes
        db.alter_table(:stdid) do
          STDID_INDEXES.each do |i|
            add_index i
          end
        end
      end
    end
  end
end


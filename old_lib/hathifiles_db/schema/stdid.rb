require 'sequel'

class HathifilesDB
  class Schema

    class StdID
      include Inject["db"]


      STDID_INDEXES_TO_DROP_AND_ADD = [:htid, :type, :value]

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

      def add(triples)
        table.import([:htid, :type, :value], triples)
      end

      def drop_indexes
        db.alter_table(:stdid) do
          STDID_INDEXES_TO_DROP_AND_ADD.each do |i|
            drop_index i
          end
        end
      end

      def add_indexes
        db.alter_table(:stdid) do
          STDID_INDEXES_TO_DROP_AND_ADD.each do |i|
            add_index i
          end
        end
      end
    end
  end
end


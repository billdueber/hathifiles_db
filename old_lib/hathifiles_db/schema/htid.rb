require 'sequel'

class HathifilesDB
  class Schema

    class HTID
      include Inject["db"]

      # All the indexes that we might want to drop (everything except
      # the :htid main id)
      HTID_INDEXES_TO_DROP_AND_ADD = [:allow, :rights_code, :record_id, :source_code,
                                      :source_record_number, :reason_code, :last_update,
                                      :govdoc, :pub_year, :collection_code,
                                      :content_provider_code, :responsible_entity, :digitization_agent]

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
          HTID_INDEXES_TO_DROP_AND_ADD.each do |i|
            LOG.info "Dropping index #{i}"
            begin
              drop_index i
            rescue Sequel::DatabaseError => e
              if e.message =~ /no such index/
                LOG.info "Index #{i} didn't exist, but we don't care. Moving on."
              else
                LOG.error "Error in drop_indexes: #{e}"
                raise e
              end
            end
          end
        end
      end

      def add_indexes
        db.alter_table(:htid) do
          HTID_INDEXES_TO_DROP_AND_ADD.each do |i|
            add_index i
          end
        end
      end


    end
  end
end

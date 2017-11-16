require 'hathifiles_db/schema/base'
require 'hathifiles_db/hathifile'

module HathifilesDB
  module Schema
    class ID < Base

      def table_name
        :id
      end

      def index_columns
        [
          :id,
          :allow,
          :rights_code,
          :record_id,
          :source_code,
          :source_record_number,
          :reason_code,
          :last_update,
          :govdoc,
          :pub_year,
          :language_code,
          :bib_format_code,
          :collection_code,
          :content_provider_code,
          :responsible_entity_code,
          :digitization_agent_code
        ]
      end

      def hathifile_tsv_columns

      end


      def create
        create_table do
          String :id
          index :id, unique: true

          TrueClass :allow, index: true

          # foreign_key :rights_code, :rights_codes, key: :code, type: String, index: true
          String :rights_code, index: true

          String :record_id, index: true
          String :enumchron

          # foreign_key :source_code, :source_codes, key: :code, type: String, index: true
          String :source_code, index: true

          String :source_record_number, index: true
          String :title, :text => true
          String :imprint, :text => true

          # foreign_key :reason_code, :reason_codes, key: :code, type: String, index: true
          String :reason_code, index: true

          DateTime :last_update, index: true
          TrueClass :govdoc, index: true

          Integer :pub_year, index: true
          String :pub_place

          String :language_code, index: true

          String :bib_format_code, index: true

          String :collection_code, index: true
          String :content_provider_code, index: true
          String :responsible_entity_code, index: true
          String :digitization_agent_code, index: true
        end
      end
    end
  end
end

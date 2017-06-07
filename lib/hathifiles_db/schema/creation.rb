require 'sequel'

class HathifilesDB
  class Schema

    class Creation

      include Inject["db"]

      def create_tables
        create_id_to_human_text_mappings
        create_htid
        create_stdid
        create_bookkeeping
      end

      def create_bookkeeping
        db.create_table(:bookkeeping) do
          String :key, primary_key: true
          String :value
        end
      end

      def create_id_to_human_text_mappings
        create_language_codes
        create_rights_codes
        create_source_codes
        create_bib_format_codes
        create_reason_codes
      end

      def create_language_codes
        db.create_table(:language_codes) do
          String :code, primary_key: true
          String :language
        end
      end

      def create_rights_codes
        db.create_table(:rights_codes) do
          String :code, primary_key: true
          String :rights
        end
      end

      def create_bib_format_codes
        db.create_table :bib_format_codes do
          String :code, primary_key: true
          String :bib_format
        end
      end

      def create_source_codes
        db.create_table :source_codes do
          String :code, primary_key: true
          String :source
        end
      end

      def create_reason_codes
        db.create_table :reason_codes do
          String :code, primary_key: true
          String :description
        end
      end


      def create_htid
        db.create_table :htid do
          String :htid, primary_key: true
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
          String :language_code
          String :bib_format_code
          #    foreign_key :language_code, :language_codes, key: :code, index: true
          #    foreign_key :bib_format_code, :bib_format_codes, key: :code, index: true
        end
      end

      def create_stdid
        db.create_table :stdid do
          String :htid, index: true
          String :type, index: true
          String :value, index: true
        end
      end
    end

  end
end

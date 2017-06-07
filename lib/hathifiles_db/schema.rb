require 'sequel'
# require 'dry-auto_inject'

class HathifilesDB
  class SchemaCreator

    attr_reader :db
    def initialize(db:)
      @db = db
    end

    def create_tables
      print "Creating tables..."
      create_id_to_human_text_mappings
      create_main
      # create_oclc
      # create_issn
      # create_isbn
      # create_lccn
      create_stdids
      create_bookkeeping
      puts "done"
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

    def create_main
      db.create_table :htid do
        String :htid, primary_key: true
        TrueClass :allow, index: true

        # foreign_key :rights_code, :rights_codes, key: :code, type: String, index: true
        String :rights_code, index: true

        String :recordid, index: true
        String :enumchron

        # foreign_key :source_code, :source_codes, key: :code, type: String, index: true
        String :source_code, index: true

        String :source_record_number, index: true
        String :title, :text=>true
        String :imprint, :text=>true

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

    def create_stdids
      db.create_table :stdids do
        String :htid, index: true
        String :type, index: true
        String :value, index: true
      end
    end

    # def create_isbn
    #   db.create_table :isbn do
    #     String :htid, type: String, index: true
    #     String :isbn
    #   end
    # end
    #
    # def create_issn
    #   db.create_table :issn do
    #     String :htid, type: String, index: true
    #     String :issn, index: true
    #   end
    # end
    #
    # def create_lccn
    #   db.create_table :lccn do
    #     String :htid, type: String, index: true
    #     String :lccn, index: true
    #   end
    # end
    #
    # def create_oclc
    #   db.create_table :oclc do
    #     String :htid, type: String, index: true
    #     String :oclc, index: true
    #   end
    # end

  end
end

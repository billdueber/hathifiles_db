require 'hathifiles_db/schema/stdid'
require 'hathifiles_db/schema/bib_format_codes'
require 'hathifiles_db/schema/bookkeeping'
require 'hathifiles_db/schema/id'


module HathifilesDB
  module Schema
    def self.subschema
      [
        STDID::OCLC,
        STDID::ISSN,
        STDID::ISBN,
        STDID::LCCN,
        BibFormatCodes,
        Bookkeeping,
        ID
      ]
    end

    def self.tsv_target_hash
      {
        id: ID.new,
        oclc: STDID::OCLC.new,
        isbn: STDID::ISBN.new,
        issn: STDID::ISSN.new,
        lccn: STDID::LCCN.new
      }
    end


    def self.create_all
      subschema.each do |klass|
        inst = klass.new
        puts "(Re)creating table #{inst.table_name}"
        inst.recreate
      end
    end

  end
end

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


    def self.create_all
      subschema.each do |klass|
        puts "Working on #{klass}"
        klass.new.recreate
      end
    end
  end
end

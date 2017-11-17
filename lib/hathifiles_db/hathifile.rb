require 'dry-initializer'

require 'hathifiles_db/schema/id'
require 'hathifiles_db/schema/stdid'

module HathifilesDB

  # An individual Hathifile, which can yield up parsed lines
  class Hathifile
    extend Dry::Initializer
    include Enumerable

    HF_COLUMNS = %i[
       id
       access
       rights_code
       record_id
       enumchron
       source_code
       source_record_number
       oclcs
       isbns
       issns
       lccns
       title
       imprint
       reason_code
       last_update
       govdoc
       pub_year
       pub_place
       language_code
       bib_format_code
       collection_code
       content_provider_code
       responsible_entity_code
       digitization_agent_code
      ]

    HF_COLUMN_INDEXES = HF_COLUMNS.each_with_index.inject({}) {|h, col_ind| h[col_ind.first] = col_ind.last; h}


    def self.from(url:, name:, datestamp:, type:)
      case type
      when 'upd'
        UpdateHathifile.new(url: url, name: name, datestamp: datestamp)
      when 'full'
        FullHathifile.new(url: url, name: name, datestamp: datestamp)
      else
        raise "Unknown hathifile type: #{type}"
      end
    end

    # Get an IO object for this file from its URL.
    # Can override the url to fech from from or
    # simply give it a file path on disk in `localfile`
    def io(url = self.url, localfile: nil)
      file_path = if localfile.nil?
                    RestClient::Request.execute(
                      method:       :get,
                      url:          url,
                      raw_response: true).file.path
                  else
                    localfile
                  end
      Zlib::GzipReader.new(File.open(file_path, 'rb'), encoding: 'utf-8')
    end

    def each
      return enum_for(:each) unless block_given?
      io.each_line do |l|
        yield l.chomp.split("\t")
      end
    end


  end

  class UpdateHathifile < Hathifile
    extend Dry::Initializer

    option :url
    option :name
    option :datestamp

    # Is this a full file (not an incremental update file)?
    def full?
      !update?
    end

    # Is this an incremental update file (not a full file)?
    def update?
      self.class == UpdateHathifile
    end


  end

  class FullHathifile < UpdateHathifile


  end

end


require 'dry-initializer'

module HathifilesDB

  # An individual Hathifile, which can yield up parsed lines
  module Hathifile

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
  end

  class UpdateHathifile
    include HathifilesDB::Inject["logger", "url", "name", "datestamp"]
    include Enumerable


    # Get an IO object for this file from its URL.
    # Can override the url to fech from from or
    # simply give it a file path on disk in `localfile`
    def io(url = self.url, localfile: nil)
      file_path = if localfile.nil?
                    logger.info "Getting file #{url}"
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


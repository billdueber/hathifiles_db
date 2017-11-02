require 'dry-initializer'

module HathifilesDB

  # An individual Hathifile, which can yield up parsed lines
  class Hathifile
    extend Dry::Initializer

    def self.from(url:, name:, datestamp:, type: )
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
    extend Dry::Initializer

    option :url
    option :name
    option :datestamp

    def full?
      !update?
    end

    def update?
      self.class == UpdateHathifile
    end

    def io(url = self.url)
      return @io if defined? @io
      resp =         RestClient::Request.execute(
        method:       :get,
        url:          url,
        raw_response: true)
      @io = Zlib::GzipReader.new(File.open(resp.file.path, 'rb'), encoding: 'utf-8')
    end

  end

  class FullHathifile < UpdateHathifile



  end

end

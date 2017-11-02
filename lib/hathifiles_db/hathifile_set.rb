require 'hathifiles_db/hathifile'

require 'oga'
require 'rest-client'

module HathifilesDB

  HATHIFILES_LIST_URL = 'https://www.hathitrust.org/hathifiles'
  # A set of links as screen-scraped off the Hathifile download page
  class HathifileSet

    def self.new_from_web(url = HATHFILES_LIST_URL)
      html = self.fetch_html(url)
      self.new(html)
    end

    def self.fetch_html(url)
      RestClient.get(url).body
    end

    attr_reader :all_links
    def initialize(html_string)
      doc = Oga::parse_html(html_string)
      @all_links = links_from_oga_doc(doc)
                     .sort {|x, y| x.datestamp <=> y.datestamp}
    end


    # Given an oga root node, get all the links and turn them into
    # HathifileDB::Link objects
    def links_from_oga_doc(doc)
      doc.css('a').find_all {|a| a.text =~ /hathi_(?:full|upd)/}.map do |a|
        url       = a.attr('href').to_s
        name      = a.text
        m         = /hathi_([\D]+)_(\d+)/.match name
        type      = m[1]
        datestamp = m[2].to_i
        Hathifile.from(url: url, name: name, type: type, datestamp: datestamp)
      end
    end

    # Call up the web page and get a list of all the links,
    # sorted by date
    def all_file_download_links(url)
      doc   = Oga::parse_html(RestClient.get(url).body)
      links = doc.css('a').find_all {|a| a.text =~ /hathi_(?:full|upd)/}
      links.map do |a|
        url       = a.attr('href').to_s
        name      = a.text
        m         = /hathi_([\D]+)_(\d+)/.match name
        type      = m[1]
        datestamp = m[2].to_i
        Link.new(url, name, type, datestamp)
      end.sort {|x, y| x.datestamp <=> y.datestamp}

    end
  end
end

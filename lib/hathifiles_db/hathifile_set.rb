require 'hathifiles_db/hathifile'

old_verbose, $VERBOSE = $VERBOSE, nil
require 'oga'
require 'rest-client'
$VERBOSE = old_verbose

module HathifilesDB

  HATHIFILES_LIST_URL = 'https://www.hathitrust.org/hathifiles'
  # A set of links as screen-scraped off the Hathifile download page
  class HathifileSet

    include Enumerable
    def each
      return enum_for(:each) unless block_given?
      catchup_files.each {|y| yield y}
    end

    def fullfile
      self.find{|x| x.full?}
    end

    def update_files
      self.find_all{|x| !x.full?}
    end

    def self.new_from_web(last_load_date:, url: HathifilesDB::HATHIFILES_LIST_URL)
      html = self.fetch_html(url)
      self.new(html, last_load_date: last_load_date)
    end

    def self.fetch_html(url)
      RestClient.get(url).body
    end

    attr_reader :all, :last_load_date
    def initialize(html_string, last_load_date: 0)
      doc = Oga::parse_html(html_string)
      @all = links_from_oga_doc(doc)
                     .sort {|x, y| x.datestamp <=> y.datestamp}
      @last_load_date = last_load_date
    end

    # Which files need to be loaded to catch up?
    def catchup_files(last_load_YYYYMMDD = last_load_date)
      if need_to_start_from_scratch?(last_load_YYYYMMDD)
        start_from_scratch_files
      else
        all.find_all{|x| x.update? and x.datestamp > last_load_YYYYMMDD}
      end
    end

    # Do we need to start from scratch?
    def need_to_start_from_scratch?(last_load_YYYYMMDD = last_load_date)
      last_load_YYYYMMDD < all.first.datestamp
    end

    # The files we need if we're going to just wipe it all out and
    # start over with the most recent full file?
    def start_from_scratch_files
      all.reverse.slice_after{|x| x.full?}.first.reverse
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

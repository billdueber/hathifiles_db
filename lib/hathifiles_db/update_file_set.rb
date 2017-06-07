require 'hathifiles_db/schema'

class HathifilesDB



  class UpdateFileSet
    include Enumerable
    include Inject["db"]



    Link = Struct.new(:url, :name, :type, :datestamp)

    # Call up the web page and get a list of all the links,
    # sorted by date
    def all_file_download_links
      doc   = Oga::parse_html(RestClient.get(URL).body)
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

    def all_links
      @all_fd_links ||= all_file_download_links
    end


    # What is the date of the most recent full dump? We'll need it
    # on first import and to re-do at the beginning of every month
    def most_recent_full_link
      all_links.find_all {|a| a.type == 'full'}.last
    end


    # Which files do we need for the update? Everything later
    # than the last update or the most recent full dump, whichever
    # is more recent
    def update_links
      last_update_date = HathifilesDB::Schema::Bookkeeping.new.last_update
      full             = most_recent_full_link
      upd              = all_links.find_all do |a|
        a.datestamp > last_update_date and
            a.datestamp >= full.datestamp
      end
    end

    def full?
      update_links.map(&:name).any? {|x| x =~ /full/}
    end

    def large?
      update_links.count > 7
    end

    def empty?
      update_links.size == 0
    end

    def most_recent_date
      update_links.last.datestamp
    end


    def drop_indexes_if_necessary
      if full? or large?
        schema = HathifilesDB::Schema.new
        schema.drop_indexes
        @dropped = true
      else
        @dropped = false
      end
      self
    end

    def add_indexes_if_necessary
      if @dropped
        schema = HathifilesDB::Schema.new
        schema.add_indexes
      end
      self
    end

    # Fetch whatever is at the end of the URI passed into
    # a temp file, and return the request handler to that
    # file
    #
    # Can't just return the path, because the temp
    # file would go out of scope and delete itself :-)
    def gzip_file_response_from_uri(uri)
      RestClient::Request.execute(
          method:       :get,
          url:          uri,
          raw_response: true)
    end

    def each
      return enum_for(:each) unless block_given?
      update_links.each do |lnk|
        LOG.info "Fetching #{lnk.name}"
        resp = gzip_file_response_from_uri(lnk.url)
        LOG.info "Processing #{lnk.name}"
        yield Zlib::GzipReader.new(File.open(resp.file.path, 'rb'))
      end
    end

  end
end

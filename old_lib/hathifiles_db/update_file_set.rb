require 'hathifiles_db/schema'
require 'hathifiles_db/schema/bookkeeping'

class HathifilesDB



  class UpdateFileSet
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
      bk = HathifilesDB::Schema::Bookkeeping.new
      last_update_date = bk.last_update
      full             = most_recent_full_link
      upd              = all_links.find_all do |a|
        a.datestamp > last_update_date and
          a.datestamp >= full.datestamp
      end
      upd
    end

    def full?
      bk = HathifilesDB::Schema::Bookkeeping.new
      last_full_file_date = bk.last_full_file_date
      LOG.info "Comparing #{last_full_file_date} to full date #{most_recent_full_link.datestamp}"
      most_recent_full_link.datestamp > last_full_file_date
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

    def count
      update_links.count
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

    def open_gzip_file(path)
      Zlib::GzipReader.new(File.open(path, 'rb'), encoding: 'utf-8')
    end

    def full_file
      return nil unless full?
      ff = most_recent_full_link
      LOG.info "Fetching full file #{ff.name}"
      resp = gzip_file_response_from_uri(ff.url)

      LOG.info "Opening full file #{ff.name}"
      open_gzip_file(resp.file.path)
    end

    def each_incremental_update_file
      update_links.reject{|ul| ul.name =~ /full/}.each do |lnk|
        LOG.info "Fetching #{lnk.name}"
        resp = gzip_file_response_from_uri(lnk.url)
        LOG.info "Processing #{lnk.name}"
        yield open_gzip_file(resp.file.path)
      end
    end

  end
end

require "hathifiles_db/version"
require 'hathifiles_db/fill_ht_constants_codes'
require 'hathifiles_db/schema'
require 'oga'
require 'rest-client'
require 'hathifiles_db/record'


class HathifilesDB
  URL = 'https://www.hathitrust.org/hathifiles'

  SQLITE_FILE = "hathifiles_sqlite.db"

  def self.sqlite_connection_string(dir)
    if defined? JRUBY_VERSION
      "jdbc:sqlite:#{dir}/#{SQLITE_FILE}"
    else
      "sqlite://#{dir}/#{SQLITE_FILE}"
    end
  end

  def self.create_new_at_db(db)
    HathifilesDB::SchemaCreator.new(db: db).create_tables
    HathifilesDB::FillHTConstantCodes.new(db: db).fill_all
    self.new(db: db)
  end

  def self.new_sqlite_db(in_dir:)
    if File.directory?(in_dir)
      connection_string = sqlite_connection_string(in_dir)
      db                = Sequel.connect connection_string
      HathifilesDB::SchemaCreator.new(db: db).create_tables
      HathifilesDB::FillHTConstantCodes.new(db: db).fill_all
      self.new(db: db)
    else
      raise "#{path} is not a directory"
    end
  end

  attr_reader :db, :all_links

  def self.open(connection_string)
    self.new(db: Sequel.connect(connection_string))
  end

  def initialize(db:)
    @db        = db
    @all_links = self.all_file_download_links
    self
  end

  def last_update_from_db
    @db[:bookkeeping].select(:value).where(key: 'last_updated').single_value.to_i
  end

  def most_recent_full_link
    @all_links.find_all {|a| a.type == 'full'}.last
  end


  def update_links
    last_update_date = last_update_from_db
    full             = most_recent_full_link
    upd              = @all_links.find_all do |a|
      a.datestamp > last_update_date and
      a.datestamp >= full.datestamp
    end
  end

  Link = Struct.new(:url, :name, :type, :datestamp)

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

  def download_to_tmp(uri)
    RestClient::Request.execute(
        method:       :get,
        url:          uri,
        raw_response: true)
  end

  def update_from_link(link)
     print "Fetching #{link.name}..."
     raw = download_to_tmp(link.url)
     print "downloaded"
     update_from_gzfile(raw.file.path)
  end

  def update_from_uri(uri)
    raw = download_to_tmp(uri)
    update_from_gzfile(raw.file.path)
  end

  SLICE_SIZES = [1000, 100]

  def send_in_batches_of(sizes, mains)
    @db.transaction do
      if sizes.empty?
        mains.each do |m|
          @db[:htid].on_duplicate_key_update.insert(m)
        end
      else
        mains.each_slice(sizes[0]) do |m|
          begin
            @db[:htid].multi_insert(m)
          rescue Sequel::UniqueConstraintViolation => e # try the next size down
            send_in_batches_of(sizes[1..-1], m)
          end
        end
      end
    end
  end


  def update_from_gzfile(path)
    htid_fields = db[:htid].columns
    total       = 0
    Zlib::GzipReader.new(File.open(path, 'rb')).each_slice(1000) do |lines|
      total       += lines.size
      insertables = lines.map {|x| HathifilesDB.data_from_raw_line(x)}
      htids       = insertables.map(&:htid)
      mains       = insertables.map(&:main)
      identifiers = insertables.inject([]) do |acc, i|
        acc.concat i.isbn
        acc.concat i.issn
        acc.concat i.oclc
        acc.concat i.lccn
        acc
      end

      send_in_batches_of(SLICE_SIZES, mains)

      @db[:stdids].where(htid: htids).delete
      @db[:stdids].multi_insert(identifiers)
      print '.'
      # HathifilesDB::HTID.new_from_line(line).save
    end
    puts " #{total}"
  end

  def update
    if update_links.empty?
      puts "Nothing to update"
      return
    end

    puts "Will load: \n  #{update_links.map(&:name).join("\n  ")}\n"
    update_links.each do |update_link|
      update_from_link(update_link)
    end
    update_last_updated_date
  end

  def update_last_updated_date
    @db[:bookkeeping].on_duplicate_key_update.insert(key: 'last_updated', value: update_links.last.datestamp)
  end

end

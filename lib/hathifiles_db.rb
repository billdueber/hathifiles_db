require "hathifiles_db/version"
require 'hathifiles_db/fill_ht_constants_codes'
require 'hathifiles_db/schema'
require 'oga'
require 'httpclient'



class HathifilesDB
  URL = 'https://www.hathitrust.org/hathifiles'

  SQLITE_FILE = "hathifiles_sqlite.db"

  def self.new_sqlite_db(in_dir:)
    if File.directory?(in_dir)
      db = Sequel.connect "sqlite://#{File.join(in_dir, SQLITE_FILE)}"
      HathifilesDB::SchemaCreator.new(db: db).create_tables
      HathifilesDB::FillHTConstantCodes.new(db: db).fill_all
      self.new(db: db)
    else
      raise "#{path} is not a directory"
    end
  end

  attr_reader :db, :all_links

  def self.open(connection_string)
    self.new(db:Sequel.connect(connection_string))
  end

  def initialize(db:)
    @db        = db
    Sequel::Model.db = db
    require 'hathifiles_db/record'
    HathifilesDB::HTID.dataset = db[:htid]
    @all_links = self.all_file_download_links
    self
  end

  def last_update_from_db
    db[:bookkeeping].select(:value).where(key: 'last_updated').single_value.to_i
  end

  def most_recent_full_link
    @all_links.find_all {|a| a.type == 'full'}.last
  end


  def update_links
    last_update_date = last_update_from_db
    full             = most_recent_full_link
    upd              = @all_links.find_all do |a|
      a.datestamp >= last_update_date and
      a.datestamp >= full.datestamp
    end

  end

  Link = Struct.new(:url, :name, :type, :datestamp)

  def all_file_download_links
    doc   = Oga::parse_html(HTTPClient.new.get_content(URL))
    links = doc.css('a').find_all {|a| a.text =~ /hathi_(?:full|upd)/}
    links.map do |a|
      url       = a.attr('href')
      name      = a.text
      m         = /hathi_([\D]+)_(\d+)/.match name
      type      = m[1]
      datestamp = m[2].to_i
      Link.new(url, name, type, datestamp)
    end.sort {|x, y| x.datestamp <=> y.datestamp}

  end

  def update

  end


end

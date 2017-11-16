require 'sequel'
require 'dry-auto_inject'

module HathifilesDB
  db = Sequel.connect('sqlite://hf.db')

  Inject = Dry::AutoInject({"db" => db})
end

require 'hathifiles_db/hathifile_set'
require 'hathifiles_db/schema'


HathifilesDB::Schema.create_all
bk = HathifilesDB::Schema::Bookkeeping.new
set = HathifilesDB::HathifileSet.new_from_web(last_load_date: bk.last_updated)




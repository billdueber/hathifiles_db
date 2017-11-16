require 'sequel'
require 'dry-auto_inject'

module HathifilesDB
  db = Sequel.connect('sqlite://hf.db')

  Inject = Dry::AutoInject({"db" => db})
end

require 'hathifiles_db/hathifile_set'
require 'hathifiles_db/schema'

puts "Zero"
HathifilesDB::Schema.create_all
puts "one"
bk = HathifilesDB::Schema::Bookkeeping.new
puts "Two"


#########
     bk.update(20171114)
#########


set = HathifilesDB::HathifileSet.new_from_web(last_load_date: bk.last_updated)
puts "Three"

require 'pry'; binding.pry

puts "Done"

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'sequel'
require 'dry-auto_inject'


if defined? ARGV[0]
  connection_string = ARGV[0]
else
  raise "Need to pass the connection string"
end

begin
  db = Sequel.connect(connection_string)
  unless db.test_connection
    raise "Nope"
  end
rescue
  raise "Unable to connect to the database"
end

unless db.tables.include? :htid
  raise "Critical table htid doesn't exist. Have you run setup_tables?"
end

Inject = Dry::AutoInject({'db' => db})
require 'hathifiles_db'
hf = HathifilesDB.new

HathifilesDB::Schema::Bookkeeping.new.last_update = 0 #20170604

hf.update

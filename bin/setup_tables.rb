$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'dry-auto_inject'
require 'sequel'

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
rescue => e
  puts e
  raise "Unable to connect to the database with #{connection_string}"
end

Inject = Dry::AutoInject({'db' => db})


### Setup over. Load it up ###

require 'hathifiles_db'
hf = HathifilesDB::Schema.new.create_new_schema

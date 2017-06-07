$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'sequel'
require 'dry-auto_inject'


connection_string = if defined? JRUBY_VERSION
                      'jdbc:mysql://localhost/hathifiles?user=dueberb'
                    else
                      'mysql2://dueberb@localhost/hathifiles'
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

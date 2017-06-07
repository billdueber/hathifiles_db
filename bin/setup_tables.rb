$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'dry-auto_inject'
require 'sequel'



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
rescue => e
  puts e
  raise "Unable to connect to the database with #{connection_string}"
end

Inject = Dry::AutoInject({'db' => db})


### Setup over ###

require 'hathifiles_db'
hf = HathifilesDB::Schema.new.create_new_schema

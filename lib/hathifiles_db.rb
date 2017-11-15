require 'sequel'
require 'dry-auto_inject'

module HathifilesDB
  db = Sequel.connect('sqlite://hf.db')

  Inject = Dry::AutoInject({"db" => db})
end


require 'hathifiles_db/schema'




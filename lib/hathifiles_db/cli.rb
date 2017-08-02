require 'thor'
require 'sequel'
require 'dry-auto_inject'
require 'hathifiles_db/logger'

class HathifilesDB

  class CLI < Thor

    def self.get_hf_from_connection_string(connection_string)
      begin
        db = Sequel.connect(connection_string)
        unless db.test_connection
          raise "Nope"
        end
      rescue => e
        raise "Unable to connect to the database with connection string '#{connection_string}'\n   Connection string must be passed in via '--db' or in ENV['HATHIFILES_CONNECTION_STRING']"
      end
      HathifilesDB.const_set('Inject', Dry::AutoInject({'db' => db}))
      require 'hathifiles_db'
      HathifilesDB.new
    end

    no_commands do
      def error_out(method, error)
        STDERR.puts "\n\n******************** ERROR ********************\n\n"
        STDERR.puts "   #{error}"
        STDERR.puts "\n******************** ERROR ********************\n\n"
        help(method)
        exit(1)
      end
    end

    CSTRING = <<-CSTRING
       The connection string must be present either in ENV['HATHIFILES_CONNECTION_STRING'] or 
       passed in with the --db option.

       The connection string should be of the form:

       \x5  * sqlite://mydir/mydb.db
       \x5  * mysql2://localhost/dbname
       \x5  * mysql2://hostname/dbname?user=USER&password=PASS

       ... or for jruby

       \x5  * jdbc:sqlite://mydir/mydb.db
       \x5  * jdbc:mysql://hostname/dbname?user=USER&password=PASS
       \x5

       \x5
    CSTRING


    #############
    # Setup
    #############

    desc "setup", "Create all the necessary tables and such in an empty database"
    long_desc <<-LONGDESC
    `hathifiles setup` will connect to the database in the connection
      string (which should be *empty*) and create all the necessary tables and indices.

       The connection string will be takend from the `--db` option if present; otherwise
       we'll look in the environment variable HATHIFILES_CONNECTION_STRING

       #{CSTRING}


    LONGDESC
    option :db, banner: "connection_string",
           desc:        "The connection string (e.g., 'sqlite://mydir/myfile.db') if not in ENV"
    def setup
      cs = (options[:db] or ENV['HATHIFILES_CONNECTION_STRING'])
      hf = self.class.get_hf_from_connection_string(cs)
      unless hf.db.tables.empty?
        raise "#{options[:db]} not empty. Database must start out empty for setup"
      end
      LOG.info "Creating new schema for database #{options[:db]}"
      HathifilesDB::Schema.new.create_new_schema
    rescue => e
      error_out(:get_hf_from_connection_string, e)
    end

    #############
    # Update
    #############

    desc "update [--db=connection_string]", "Update the prepared database to be current"
    long_desc <<-UPDATELONGDESC
      Update the database with the latest files from the hathitrust website. Will do a bulk-import if you 
      need to get the full file.

      Automatically runs `setup` if the database exists and is empty.

      Uses temporary files, so make sure Dir.tmpdir ('/tmp' by default on unix-likes) has enough
      space!

      #{CSTRING}

    UPDATELONGDESC
    option :db, banner: "connection_string",
           desc:        "The connection string (e.g., 'sqlite://mydir/myfile.db') if not in ENV"
    option :'force-reload', type: :boolean, desc: "Force a reload of every line, even if the program thinks it's unnecessary", default: false
    def update
      cs = (options[:db] or ENV['HATHIFILES_CONNECTION_STRING'])

      hf = self.class.get_hf_from_connection_string(cs)
      LOG.info "Updating #{cs}..."

      if hf.db.tables.empty?
        LOG.info "DB is empty. Creating new schema for database #{cs}"
        HathifilesDB::Schema.new.create_new_schema
      end

      last_update = hf.bookkeeping.last_update
      if last_update == 0
        last_update = 'never'
      end
      LOG.info "Last updated: #{last_update}"

      if options[:force_reload]
        LOG.info "Forcing reload of all items"
        hf.bookkeeping.last_update = 0
      end
      hf.update
    rescue => e
      raise e
      error_out(:update, e)
    end

    desc :console, "Start a pry console"
    option :db, banner: "connection_string",
           desc:        "The connection string (e.g., 'sqlite://mydir/myfile.db') if not in ENV"
    def console
      cs = (options[:db] or ENV['HATHIFILES_CONNECTION_STRING'])

      hf = self.class.get_hf_from_connection_string(cs)
      require 'pry'
      binding.pry
    end


  end
end

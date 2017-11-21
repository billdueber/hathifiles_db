##### ARRRRGH! Need to update the bookkeeping table! ####

$:.unshift 'lib'
require 'yell'
require 'sequel'
require 'dry-auto_inject'

ENV['TSVDIR'] = '..'
Log = Yell.new STDOUT
module HathifilesDB
  connection_string = if defined? JRUBY_VERSION
                        "jdbc:sqlite:///Users/dueberb/devel/hathi/hf.db"
                      else
                        'sqlite://../hf.db'
                      end
  
  db = Sequel.connect(connection_string)

  Inject = Dry::AutoInject({"db" => db, "logger" => ::Log})
end


require 'hathifiles_db'
require 'hathifiles_db/hathifile_set'
require 'hathifiles_db/schema'


####################
## Messing around ##
##                ##
####################

HathifilesDB::Schema.create_all unless HathifilesDB::Schema::ID.new.exists?

bk  = HathifilesDB::Schema::Bookkeeping.new
db  = bk.db

update_date = bk.last_updated
# update_date = 20171117
set = HathifilesDB::HathifileSet.new_from_web(last_load_date: update_date)


ff = set.fullfile
if ff
  Log.info "Full file is #{ff.name}"
else
  Log.info "No need to update from full file. Continuing"
end

Log.info "Update files\n  #{set.update_files.map(&:name).join("\n  ")}"

recent = set.update_files.last


@schemas_to_target = HathifilesDB::Schema.tsv_target_hash

def ppn(num)
  num.to_s.reverse.scan(/.{1,3}/).join("_").reverse
end

def add_full_file(hathifile)
  Log.warn "Need to start with full file. Gonna take a bit"
  log_interval = 500_000
  @schemas_to_target.values.each do |s|
    s.drop_table
    s.create
    s.drop_indexes
  end

  tsvs = @schemas_to_target.map do |k, v|
    HathifilesDB::TSV.new("#{k}.tsv", writeable: true, schema: v)
  end

  Log.warn "Dumping full file to tab-delimited files for bulk import"
  hathifile.each_with_index do |rawline, i|
    Log.info "Starting to dump #{hathifile.name} to tab-delimited files" if i == 0
    Log.info "%12s items written to tsv files" % ppn(i) if i % log_interval == 0 and i > 0
    tsvs.each do |tsv|
      tsv << rawline
    end
  end

  @schemas_to_target.each_pair do |table, schema|
    Log.info "Beginning import of #{table}"
    schema.import_tsv_into_sqlite("#{table}.tsv")
  end

  @schemas_to_target.each_pair do |table, schema|
    Log.info "Adding indexes to #{table}"
    schema.create_indexes
  end
end

def add_update_file(hathifile)
  Log.info "Updating from #{hathifile.name}"
  i = 1
  slice_size = 1000
  hathifile.each_slice(slice_size) do |hundred_lines|
    @schemas_to_target.values.each do |schema|
      schema << hundred_lines
    end
    total = i * slice_size
    Log.info "   #{total} items" if total % 5000 == 0
    i += 1
  end
end


set.catchup_files.each do |index_file|
  Log.info "Fetching #{index_file.name}"
  if index_file.full?
    add_full_file(index_file)
  else
    add_update_file(index_file)
  end
end

lud = set.catchup_files.last.datestamp
Log.info "Setting last_updated date to #{lud}"
bk.update(lud)

Log.info "Done"

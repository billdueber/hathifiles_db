require 'sequel'
require 'dry-auto_inject'
require 'hathifiles_db/intermediate_tsv'

require 'yell'
Log = Yell.new STDOUT


__END__

module HathifilesDB
  db = Sequel.connect('sqlite://hf.db')

  Inject = Dry::AutoInject({"db" => db})
end

require 'hathifiles_db/hathifile_set'
require 'hathifiles_db/schema'


####################
## Messing around ##
##                ##
####################

HathifilesDB::Schema.create_all
bk = HathifilesDB::Schema::Bookkeeping.new
db = bk.db
set = HathifilesDB::HathifileSet.new_from_web(last_load_date: bk.last_updated)

ff = set.fullfile
Log.info "Full file is #{ff.name}" if ff
Log.info "Update files\n  #{set.update_files.map(&:name).join("\n  ")}"

recent = set.update_files.last


schemas_to_target = HathifilesDB::Schema.tsv_target_hash

tsvs = schemas_to_target.map do |k, v|
  HathifilesDB::TSV.new("#{k}.tsv", writeable: true, schema: v)
end

def ppn(num)
  num.to_s.reverse.scan(/.{1,3}/).join("_").reverse
end

index_file = ff

interval = index_file.full? ? 250_000 : 5_000
Log.info "Fetching #{index_file.name}"
index_file.each_with_index do |rawline, i|
  Log.info "Starting to index #{index_file.name}" if i == 0
  Log.info "%12s written to tsv file" % ppn(i)  if i % interval == 0 and i > 0
  # schemas_to_target.values.each do |s|
  #   s << rawline
  # end

  tsvs.each do |tsv|
    tsv << rawline
  end
end

Log.info "\nBeginning import"
schemas_to_target.each_pair do |table, schema|
  schema.import_tsv_into_sqlite("#{table}.tsv")
end

Log.info "Adding indexes"
schemas_to_target.each_pair do |table, schema|
  schema.create_indexes
end

Log.info "Done"

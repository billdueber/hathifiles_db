# Oga throws all sorts of warnings. Suppress

old_verbose = $VERBOSE
$VERBOSE = nil
require 'oga'
$VERBOSE = old_verbose
require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
  config.order = :random
  Kernel.srand config.seed
end

# Set up a db for testing

require 'dry-auto_inject'
require 'sequel'
module HathifilesDB
  Inject = Dry::AutoInject({'db' => Sequel.connect('sqlite:/') })
end

# Load test data
require 'pathname'
DDIR = Pathname.new(__dir__) + 'data'

def data_file(filename)
  DDIR + filename
end

def data_file_content(filename)
  File.read(data_file(filename))
end



# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hathifiles_db/version'

Gem::Specification.new do |spec|
  spec.name          = "hathifiles_db"
  spec.version       = HathifilesDB::VERSION
  spec.authors       = ["Bill Dueber"]
  spec.email         = ["bill@dueber.com"]

  spec.summary       = %q{Keep a database of the data in the hathifiles}
  spec.homepage      = "https://github.com/billdueber/hathifiles_db"
  spec.license       = "MIT"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'dry-auto_inject'
  spec.add_dependency 'dry-initializer'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'sequel'
  spec.add_dependency 'oga'
  spec.add_dependency 'yell'
  # spec.add_dependency 'thor'
  spec.add_dependency 'library_stdnums'

  if defined? JRUBY_VERSION
    spec.add_dependency 'jdbc-sqlite3'
    spec.add_dependency 'jdbc-mysql'
  else
    spec.add_dependency 'sqlite3'
    spec.add_dependency 'mysql2'
  end



  spec.add_development_dependency "rspec"
end

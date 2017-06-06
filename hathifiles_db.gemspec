# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hathifiles_db/version'

Gem::Specification.new do |spec|
  spec.name          = "hathifiles_db"
  spec.version       = HathifilesDB::VERSION
  spec.authors       = ["Bill Dueber"]
  spec.email         = ["bill@dueber.com"]

  spec.summary       = %q{Create/update a hathifiles database}
  spec.homepage      = "http://hathitrust.org/"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sequel"
  spec.add_dependency "dry-initializer"
  spec.add_dependency 'dry-types'
  spec.add_dependency 'oga'
  spec.add_dependency 'httpclient'

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end

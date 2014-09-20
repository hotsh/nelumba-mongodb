# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nelumba-mongodb/version'

Gem::Specification.new do |gem|
  gem.name          = "nelumba-mongodb"
  gem.version       = Nelumba::MONGODB_VERSION
  gem.authors       = ["wilkie"]
  gem.email         = ["wilkie@xomb.com"]
  gem.description   = %q{A persistence layer for nelumba.}
  gem.summary       = %q{A persistence layer for nelumba.}
  gem.homepage      = "https://github.com/hotsh/nelumba-mongodb"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  #gem.add_dependency "nelumba"
  gem.add_dependency "redcarpet"    # Markdown renderer
  gem.add_dependency "bson_ext"     # Database
  gem.add_dependency "mongo_mapper" # Database
  gem.add_dependency "bcrypt-ruby"  # Basic Authentication
  gem.add_dependency "rmagick"      # Used for avatar resizing
end

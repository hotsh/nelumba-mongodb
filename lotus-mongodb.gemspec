# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lotus-mongodb/version'

Gem::Specification.new do |gem|
  gem.name          = "lotus-mongodb"
  gem.version       = Lotus::MONGODB_VERSION
  gem.authors       = ["wilkie"]
  gem.email         = ["wilkie@xomb.com"]
  gem.description   = %q{A persistence layer for lotus.}
  gem.summary       = %q{A persistence layer for lotus.}
  gem.homepage      = "https://github.com/hotsh/lotus-mongodb"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  #gem.add_dependency "lotus"
  gem.add_dependency "redcarpet"    # Markdown renderer
  gem.add_dependency "bson_ext"     # Database
  gem.add_dependency "mongo_mapper" # Database
  gem.add_dependency "bcrypt-ruby"  # Basic Authentication
  gem.add_dependency "rmagick"      # Used for avatar resizing
end

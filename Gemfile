source 'https://rubygems.org'

# Specify your gem's dependencies in lotus-mongodb.gemspec
gemspec

gem "redfinger", :git => "git://github.com/hotsh/redfinger.git"
gem 'lotus', :git => 'git://github.com/hotsh/lotus.git'

group :test do
  gem "rake"              # rakefile
  gem "minitest", "4.7.0" # test framework (specified here for prior rubies)
  gem "ansi"              # minitest colors
  gem "turn"              # minitest output
  gem "mocha"             # stubs
  gem "debugger"          # debugging

  gem "awesome_print"
  gem "rack-test"
end

require 'lotus'
require 'mongo_mapper'

MongoMapper.setup({
  'default' => {
    'database' => ENV['MONGOHQ_DATABASE'] ||
                  ENV['MONGODB_DATABASE'] ||
                  'lotus-mongodb',
    'uri'      => ENV['MONGOHQ_URL'] ||
                  ENV['MONGODB_URI'] ||
                  ENV['MONGOLAB_URI']
  }
}, 'default')

require "lotus-mongodb/embedded_object"
require "lotus-mongodb/object"

require "lotus-mongodb/identity"
require "lotus-mongodb/activity"
require "lotus-mongodb/feed"
require "lotus-mongodb/person"
require "lotus-mongodb/authorization"
require "lotus-mongodb/avatar"

require "lotus-mongodb/note"
require "lotus-mongodb/article"
require "lotus-mongodb/comment"
require "lotus-mongodb/image"

module Lotus
  BCRYPT_ROUNDS = 13

  def create_person
  end
end

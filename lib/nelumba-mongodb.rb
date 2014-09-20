require 'nelumba'
require 'mongo_mapper'

MongoMapper.setup({
  'default' => {
    'database' => ENV['MONGOHQ_DATABASE'] ||
                  ENV['MONGODB_DATABASE'] ||
                  'nelumba-mongodb',
    'uri'      => ENV['MONGOHQ_URL'] ||
                  ENV['MONGODB_URI'] ||
                  ENV['MONGOLAB_URI']
  }
}, 'default')

require "nelumba-mongodb/embedded_object"
require "nelumba-mongodb/object"

require "nelumba-mongodb/identity"
require "nelumba-mongodb/activity"
require "nelumba-mongodb/feed"
require "nelumba-mongodb/person"
require "nelumba-mongodb/authorization"
require "nelumba-mongodb/avatar"

require "nelumba-mongodb/note"
require "nelumba-mongodb/article"
require "nelumba-mongodb/comment"
require "nelumba-mongodb/image"

module Nelumba
  BCRYPT_ROUNDS = 13

  def create_person
  end
end

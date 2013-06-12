require 'lotus'
require 'mongo_mapper'

MongoMapper.database = "lotus-mongodb"

require "lotus-mongodb/aggregate"
require "lotus-mongodb/identity"
require "lotus-mongodb/activity"
require "lotus-mongodb/feed"
require "lotus-mongodb/person"
require "lotus-mongodb/authorization"
require "lotus-mongodb/author"
require "lotus-mongodb/avatar"

module Lotus
  BCRYPT_ROUNDS = 13

  def create_person
  end
end

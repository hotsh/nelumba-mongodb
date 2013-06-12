require 'minitest/spec'
require 'turn/autorun'

Turn.config do |c|
  c.natural = true
end

require "mocha/setup"
require "debugger"

require 'mongo_mapper'

require 'lotus'

module ActiveSupport::Callbacks::ClassMethods
  def callbacks
    return @callbacks if @callbacks

    @callbacks ||= {}
    [:create, :save].each do |method|
      self.send(:"_#{method}_callbacks").each do |callback|
        @callbacks[:"#{callback.kind}_#{method}"] ||= []
        @callbacks[:"#{callback.kind}_#{method}"] << callback.raw_filter
      end
    end
    @callbacks
  end

  def before_create_callbacks
    callbacks[:before_create]
  end

  def after_create_callbacks
    callbacks[:after_create]
  end
end

module MongoMapper::Plugins::Associations::ClassMethods
  def has_one?(id)
    association = self.associations[id]
    return nil unless association

    association.is_a? MongoMapper::Plugins::Associations::OneAssociation
  end

  def belongs_to?(id)
    association = self.associations[id]
    return nil unless association

    association.is_a? MongoMapper::Plugins::Associations::BelongsToAssociation
  end

  def has_many?(id)
    association = self.associations[id]
    return nil unless association

    association.is_a? MongoMapper::Plugins::Associations::ManyAssociation
  end
end

require_relative '../lib/lotus-mongodb/person'
require_relative '../lib/lotus-mongodb/identity'
require_relative '../lib/lotus-mongodb/author'
require_relative '../lib/lotus-mongodb/feed'
require_relative '../lib/lotus-mongodb/aggregate'
require_relative '../lib/lotus-mongodb/avatar'
require_relative '../lib/lotus-mongodb/activity'
require_relative '../lib/lotus-mongodb/authorization'

MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database = "lotus-test"

class MiniTest::Unit::TestCase
  def teardown
    MongoMapper.database.collections.each do |collection|
      collection.remove unless collection.name.match /^system\./
    end
  end
end

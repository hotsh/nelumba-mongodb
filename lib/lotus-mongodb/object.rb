module Lotus
  module Object
    def self.included(klass)
      klass.class_eval do
        def initialize(*args)
          super(*args)
        end

        include MongoMapper::Document

        belongs_to :author, :class_name => 'Lotus::Person'
        key :author_id, ObjectId

        key :title
        key :uid
        key :url
        key :display_name
        key :summary
        key :content
        key :image

        timestamps!

        def published
          self.created_at
        end

        def updated
          self.updated_at
        end
      end
    end
  end
end

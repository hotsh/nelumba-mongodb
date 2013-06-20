module Lotus
  module EmbeddedObject
    def self.included(klass)
      klass.class_eval do
        def initialize(*args)
          super(*args)
        end

        include MongoMapper::EmbeddedDocument

        belongs_to :author, :class_name => 'Lotus::Author'
        key :author_id, ObjectId

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

        embedded_in :'Lotus::Activity'
      end
    end
  end
end

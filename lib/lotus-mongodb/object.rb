module Lotus
  module Object
    def self.included(klass)
      klass.class_eval do
        include MongoMapper::Document

        def initialize(*args, &blk)
          init(*args, &blk)

          super(*args, &blk)
        end

        # Ensure writes happen (lol mongo defaults)
        safe

        belongs_to :author, :class_name => 'Lotus::Person'
        key :author_id, ObjectId

        key :title
        key :uid
        key :url
        key :display_name
        key :summary
        key :content
        key :image

        key :text
        key :html

        # Automated Timestamps
        key :published, Time
        key :updated,   Time
        before_save :update_timestamps

        def update_timestamps
          now = Time.now.utc
          self[:published] ||= now if !persisted?
          self[:updated]     = now
        end
      end
    end
  end
end

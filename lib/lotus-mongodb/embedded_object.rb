module Lotus
  module EmbeddedObject
    def self.included(klass)
      klass.class_eval do
        include MongoMapper::EmbeddedDocument

        belongs_to :author, :class_name => 'Lotus::Person'
        key :author_id, ObjectId

        key :title
        key :uid
        key :url
        key :display_name
        key :summary
        key :content
        key :image

        # Automated Timestamps
        key :published, Time
        key :updated,   Time
        before_save :update_timestamps

        def update_timestamps
          now = Time.now.utc
          self[:published] ||= now if !persisted?
          self[:updated]     = now
        end

        def self.find_by_id(id)
          Lotus::Activity.object_by_id_and_type(id, self)
        end

        embedded_in :'Lotus::Activity'
      end
    end
  end
end

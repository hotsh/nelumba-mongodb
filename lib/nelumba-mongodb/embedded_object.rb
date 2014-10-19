module Nelumba
  module EmbeddedObject
    def self.included(klass)
      klass.class_eval do
        include MongoMapper::EmbeddedDocument

        def initialize(*args, &blk)
          init(*args, &blk)

          super(*args, &blk)
        end

        def init(*args, &blk)
          # Default author negotiation
          unless blk
            blk = Nelumba::Person.method(:find_by_username_and_domain)
          end

          super *args, &blk
        end

        belongs_to :author, :class_name => 'Nelumba::Person'
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
          Nelumba::Activity.object_by_id_and_type(id, self)
        end

        embedded_in :'Nelumba::Activity'
      end
    end
  end
end

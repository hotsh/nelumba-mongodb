module Nelumba
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

        # An Array of Persons that create the content in this Feed.
        key  :authors_ids,  Array, :default => []
        many :authors,      :class_name => 'Nelumba::Person', :in => :authors_ids

        key :title
        key :title_type
        key :uid
        key :url
        key :display_name
        key :summary
        key :content
        key :image

        has_one :source, :class_name => 'Nelumba::Feed'

        key :text
        key :html

        # Contains the Activity this Activity is a response of.
        key :in_reply_to_ids, Array
        many :in_reply_to, :in => :in_reply_to_ids, :class_name => 'Nelumba::Activity'

        # Automated Timestamps
        key :published, Time
        key :updated,   Time
        before_save :update_timestamps

        # Contains the source of this Activity if it is a repost or otherwise copied
        # from another Feed.
        key :source, :class_name => 'Nelumba::Feed'

        # Contains the Activities that are replies to this one
        key :replies_ids, Array
        many :replies, :in => :replies_ids, :class_name => 'Nelumba::Activity'

        # Contains the Persons this Activity mentions.
        key :mentions_ids, Array
        many :mentions, :in => :mentions_ids, :class_name => 'Nelumba::Person'

        # Contains the Persons that have shared this activity
        key :shares_ids, Array
        many :shares, :in => :shares_ids, :class_name => 'Nelumba::Person'

        # Contains the Persons that have liked this activity
        key :likes_ids, Array
        many :likes, :in => :likes_ids, :class_name => 'Nelumba::Person'

        # Hash containing various interaction metadata
        key :interactions

        def update_timestamps
          now = Time.now.utc
          self[:published] ||= now if !persisted?
          self[:updated]     = now
        end
      end
    end
  end
end

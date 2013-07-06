module Lotus
  class Feed
    def initialize(*args); super(*args); end

    include MongoMapper::Document

    # An Aggregate handles subscriptions to this Feed.
    key :aggregate_id, ObjectId
    belongs_to :aggregate, :class_name => 'Lotus::Aggregate'

    # A unique identifier for this Feed.
    key :uid

    # A URL for this Feed that can be used to retrieve a representation.
    key :url

    remove_method :categories
    key :categories,   :default => []

    # The type of rights one has to this feed generally for human display.
    key :rights

    # The title of this feed.
    key :title

    # The representation of the title. (e.g. "html")
    key :title_type

    # The subtitle of the feed.
    key :subtitle

    # The representation of the subtitle. (e.g. "html")
    key :subtitle_type

    # An array of Persons that contributed to this Feed.
    key  :contributors_ids, Array, :default => []
    remove_method :contributors
    many :contributors,     :class_name => 'Lotus::Person', :in => :contributors_ids

    # An Array of Persons that create the content in this Feed.
    key  :authors_ids,  Array, :default => []
    remove_method :authors
    many :authors,      :class_name => 'Lotus::Person', :in => :authors_ids

    # An Array of Activities that are contained in this Feed.
    key :items_ids,  Array
    many :items,     :class_name => 'Lotus::Activity',
                     :in         => :items_ids,
                     :order      => :created_at.desc

    # A Hash containing information about the entity that is generating content
    # for this Feed when it isn't a person.
    key :generator

    # Feeds may have an icon to represent them.
    #key :icon, :class_name => 'Image'

    # Feeds may have an image they use as a logo.
    #key :logo, :class_name => 'Image'

    # TODO: Normalize the first 100 or so activities. I dunno.
    key :normalized

    # Log modification
    timestamps!

    # Create a new Feed if the given Feed is not found by its id.
    def self.find_or_create_by_uid!(arg, *args)
      if arg.is_a? Lotus::Feed
        uid = arg.uid
      else
        uid = arg[:uid]
      end

      feed = self.first(:uid => uid)
      return feed if feed

      begin
        feed = create!(arg, *args)
      rescue
        feed = self.first(:uid => uid) or raise
      end

      feed
    end

    # Create a new Feed from a Hash of values or a Lotus::Feed.
    def initialize(*args)
      hash = {}
      if args.length > 0
        hash = args.shift
      end

      if hash.is_a? Lotus::Feed
        hash = hash.to_hash

        hash[:authors].map! do |a|
          Person.find_or_create_by_uid!(a, :safe => true)
        end

        hash[:contributors].map! do |a|
          Person.find_or_create_by_uid!(a, :safe => true)
        end

        hash[:items].map! do |a|
          Lotus::Activity.find_or_create_by_uid!(a, :safe => true)
        end
      end

      super hash, *args
    end

    # Discover a feed by the given feed location or account.
    def self.discover!(feed_identifier)
      feed = Feed.first(:url => feed_identifier)
      return feed if feed

      feed = Lotus.discover_feed(feed_identifier)
      return false unless feed

      existing_feed = Feed.first(:uid => feed.uid)
      return existing_feed if existing_feed

      self.create!(feed)
    end

    # Adds activity to the feed.
    def post!(activity)
      if activity.is_a?(Hash)
        # Create a new activity
        activity = Lotus::Activity.create!(activity)
      end

      activity.feed_id = self.id
      activity.save

      self.items << activity
      self.save

      activity
    end

    # Reposts an activity from another feed.
    def repost!(activity)
      self.items << activity
      self.save
    end

    # Deletes the activity from this feed.
    def delete!(activity)
      self.items_ids.delete(activity.id)
      self.save
    end

    # Merges the information in the given feed with this one.
    def merge!(feed)
      # Merge metadata
      meta_data = feed.to_hash
      meta_data.delete :items
      meta_data.delete :authors
      meta_data.delete :contributors
      meta_data.delete :uid
      self.update_attributes!(meta_data)

      # Merge new/updated authors
      feed.authors.each do |author|
      end

      # Merge new/updated contributors
      feed.contributors.each do |author|
      end

      # Merge new/updated activities
      feed.items.each do |activity|
      end
    end

    # Retrieve the feed's activities with the most recent first.
    def ordered
      Lotus::Activity.where(:id => self.items_ids).order(:created_at => :desc)
    end
  end
end

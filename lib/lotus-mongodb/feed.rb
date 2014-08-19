module Lotus
  class Feed
    def initialize(*args); super(*args); end

    include MongoMapper::Document

    # Ensure writes happen
    safe

    # A unique identifier for this Feed.
    key :uid

    # A URL for this Feed that can be used to retrieve a representation.
    key :url

    # Feeds generally belong to a person.
    key :person_id, ObjectId
    belongs_to :person, :class_name => 'Lotus::Person'

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
                     :order      => :published.desc

    # A Hash containing information about the entity that is generating content
    # for this Feed when it isn't a person.
    key :generator

    # Feeds may have an icon to represent them.
    #key :icon, :class_name => 'Image'

    # Feeds may have an image they use as a logo.
    #key :logo, :class_name => 'Image'

    # TODO: Normalize the first 100 or so activities. I dunno.
    key :normalized

    # Automated Timestamps
    key :published, Time
    key :updated,   Time
    before_save :update_timestamps

    def update_timestamps
      now = Time.now.utc
      self[:published] ||= now if !persisted?
      self[:updated]     = now
    end

    # The external feeds being aggregated.
    key  :following_ids, Array
    many :following,     :in => :following_ids, :class_name => 'Lotus::Feed'

    # Who is aggregating this feed.
    key  :followers_ids, Array
    many :followers,     :in => :followers_ids, :class_name => 'Lotus::Feed'

    # Subscription status.
    # Since subscriptions are done by the server, we only need to share one
    # secret/token pair for all users that follow this feed on the server.
    # This is done at the Feed level since people may want to follow your
    # "timeline", or your "favorites". Or People who use Lotus will ignore
    # the Person aggregate class and go with their own thing.
    key :subscription_secret
    key :verification_token

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
      end

      if hash[:authors].is_a? Array
        hash[:authors].map! do |author|
          if author.is_a? Hash
            author = Lotus::Person.find_or_create_by_uid!(author)
          end
          author
        end
      end

      if hash[:contributors].is_a? Array
        hash[:contributors].map! do |contributor|
          if contributor.is_a? Hash
            contributor = Lotus::Person.find_or_create_by_uid!(contributor)
          end
          contributor
        end
      end

      if hash[:items].is_a? Array
        hash[:items].map! do |item|
          if item.is_a? Hash
            item = Lotus::Activity.find_or_create_by_uid!(item)
          end
          item
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
      Lotus::Activity.where(:id => self.items_ids).order(:published => :desc)
    end

    # Follow the given feed. When a new post is placed in this feed, it
    # will be copied into ours.
    def follow!(feed)
      self.following << feed
      self.save

      # Subscribe to that feed on this server if not already.
    end

    # Unfollow the given feed. Our feed will no longer receive new posts from
    # the given feed.
    def unfollow!(feed)
      self.following_ids.delete(feed.id)
      self.save
    end

    # Denotes that the given feed will contain your posts.
    def followed_by!(feed)
      self.followers << feed
      self.save
    end

    # Denotes that the given feed will not contain your posts from now on.
    def unfollowed_by!(feed)
      self.followers_ids.delete(feed.id)
      self.save
    end

    # Add to the feed and tell subscribers.
    def post!(activity)
      if activity.is_a?(Hash)
        # Create a new activity
        activity = Lotus::Activity.create!(activity)
      end

      activity.feed_id = self.id
      activity.save

      self.items << activity
      self.save

      publish(activity)

      activity
    end

    # Remove the activity from the feed.
    def delete!(activity)
      self.items_ids.delete(activity.id)
      self.save
    end

    # Add a copy to our feed and tell subscribers.
    def repost!(activity)
      self.items << activity
      self.save

      publish(activity)
    end

    # Publish an activity that is within our feed.
    def publish(activity)
      # Push to direct followers
      self.followers.each do |feed|
        feed.repost! activity
      end

      # TODO: PuSH Hubs
    end
  end
end

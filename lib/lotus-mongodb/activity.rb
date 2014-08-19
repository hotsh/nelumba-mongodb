module Lotus
  class Activity
    include Lotus::Object

    # All Activities originate from one particular Feed.
    key :feed_id, ObjectId
    belongs_to :feed, :class_name => 'Lotus::Feed'

    # Determines what type of object this Activity represents. Standard types
    # include:
    #   :article, :audio, :bookmark, :comment, :file, :folder, :group,
    #   :list, :note, :person, :photo, :"photo-album", :place, :playlist,
    #   :product, :review, :service, :status, :video
    key :type

    # Determines the action this Activity represents. Standard types include:
    #   :favorite, :follow, :like, :"make-friend", :join, :play,
    #   :post, :save, :share, :tag, :update
    key :verb

    # Determines what is acting.
    key :actor_id, ObjectId
    key :actor_type, String

    # Determines what the action is acting upon.
    key :target_id, ObjectId
    key :target_type, String

    # Can attach an external object to this Activity.
    key :external_object_id, ObjectId
    key :external_object_type, String

    # Optionally, an object can be embedded inside an Activity.
    one :embedded_object, :class_name => "Lotus::Comment", :polymorphic => true

    # The title of the Activity.
    key :title

    # Contains the source of this Activity if it is a repost or otherwise copied
    # from another Feed.
    key :source, :class_name => 'Lotus::Feed'

    # Contains the Activity this Activity is a response of.
    key :in_reply_to_ids, Array
    remove_method :in_reply_to
    many :in_reply_to, :in => :in_reply_to_ids, :class_name => 'Lotus::Activity'

    # Contains the Activities that are replies to this one
    key :replies_ids, Array
    remove_method :replies
    many :replies, :in => :replies_ids, :class_name => 'Lotus::Activity'

    # Contains the Persons this Activity mentions.
    key :mentions_ids, Array
    remove_method :mentions
    many :mentions, :in => :mentions_ids, :class_name => 'Lotus::Person'

    # Contains the Persons that have shared this activity
    key :shares_ids, Array
    remove_method :shares
    many :shares, :in => :shares_ids, :class_name => 'Lotus::Person'

    # Contains the Persons that have liked this activity
    key :likes_ids, Array
    remove_method :likes
    many :likes, :in => :likes_ids, :class_name => 'Lotus::Person'

    # Ensure that url and uid for the activity are set
    before_create :ensure_uid_and_url

    # Scrape content for mentions
    before_create :scrape_mentions

    private

    # Ensure uid and url are established. If they don't exist, just use urls
    # that point to us for the sake of uniqueness.
    def ensure_uid_and_url
      unless self.uid && self.url
        self.uid = "/activities/#{self.id}"
        self.url = "/activities/#{self.id}"
      end
    end

    # Scrape content for username mentions.
    def scrape_mentions
      return if self.object.nil?
      return unless !self.object.is_a?(Lotus::Person) &&
                    self.object.respond_to?(:mentions)
      authors = self.object.mentions do |username, domain|
        i = Identity.first(:username => /^#{Regexp.escape(username)}$/i)
        i.person if i
      end
      authors ||= []
      self.mentions_ids = authors.compact.map(&:id)
    end

    public

    def mentions?(author)
      if author.is_a? Lotus::Identity
        author = author.person
      end

      self.mentions_ids.include? author.id
    end

    def self.article_by_id(id)
      self.object_by_id_and_type(id, Lotus::Article)
    end

    def self.note_by_id(id)
      self.object_by_id_and_type(id, Lotus::Note)
    end

    def self.object_by_id(id)
      oid = id
      if id.is_a? String
        oid = BSON::ObjectId.from_string(id)
      end

      activity = Lotus::Activity.first("embedded_object._id" => oid)
      activity.object if activity
    end

    def self.object_by_id_and_type(id, type)
      obj = self.object_by_id(id)
      return obj if obj.is_a? type
      nil
    end

    # Intern, for consistency, standard object types.
    def type=(type)
      if STANDARD_TYPES.map(&:to_s).include? type
        type = type.intern
      end

      super type
    end

    # Set the actor.
    def actor=(obj)
      if obj.nil?
        self.actor_id = nil
        self.actor_type = nil
        return
      end

      @actor = obj

      self.actor_id   = obj.id
      self.actor_type = obj.class.to_s
      self.actor_type = self.actor_type[7..-1] if self.actor_type.start_with? "Lotus::"
    end

    # Get the actor.
    def actor
      return @actor if @actor

      return nil if self.actor_type && !Lotus.const_defined?(self.actor_type)
      klass = Lotus.const_get(self.actor_type) if self.actor_type
      @actor = klass.first(:id => self.actor_id) if klass && self.actor_id
    end

    # Set the object.
    def object=(obj)
      if obj.nil?
        self.external_object_id = nil
        self.external_object_type = nil
      elsif obj.class.respond_to?(:embeddable?) && obj.class.embeddable?
        self.embedded_object = obj
        self.external_object_id = nil
        self.external_object_type = nil
      else
        self.embedded_object = nil
        self.external_object_id   = obj.id
        self.external_object_type = obj.class.to_s
        if self.external_object_type.start_with? "Lotus::"
          self.external_object_type = self.external_object_type[7..-1]
        end
      end
      @object = obj
    end

    # Get the object.
    def object
      return @object if @object

      return @object = self.embedded_object if self.embedded_object
      return @object = self unless self.external_object_type

      return nil if self.external_object_type && !Lotus.const_defined?(self.external_object_type)
      klass = Lotus.const_get(self.external_object_type) if self.external_object_type
      @object = klass.find_by_id(self.external_object_id) if klass && self.external_object_id
    end

    # Create a new Activity if the given Activity is not found by its id.
    def self.find_or_create_by_uid!(arg, *args)
      if arg.is_a? Lotus::Activity
        uid = arg.uid
      else
        uid = arg[:uid]

        if arg[:author]
          arg[:author] = Person.find_or_create_by_uid!(arg[:author])
        end
      end

      activity = self.first(:uid => uid)
      return activity if activity

      begin
        if arg.is_a? Lotus::Activity
          arg.save
        else
          activity = create!(arg, *args)
        end
      rescue
        activity = self.first(:uid => uid) or raise
      end

      activity
    end

    # Create a new Activity from a Hash of values or a Lotus::Activity.
    def self.create!(*args)
      hash = {}
      if args.length > 0
        hash = args.shift
      end

      if hash.is_a? Lotus::Activity
        hash = hash.to_hash

        hash.delete :author
        hash.delete :in_reply_to
      end

      super hash, *args
    end

    # Create a new Activity from a Hash of values or a Lotus::Activity.
    def self.create(*args)
      self.create! *args
    end

    # Discover a feed by the given activity location.
    def self.discover!(activity_identifier)
      activity = Lotus::Activity.first(:url => activity_identifier)
      return activity if activity

      activity = Lotus.discover_activity(activity_identifier)
      return false unless activity

      existing = Activity.first(:uid => activity.uid)
      return existing if existing

      self.create!(activity)
    end

    # Yields the parts of speech for the activity. Returns a hash with the
    # following:
    #
    # :verb         => The action being performed by the subject.
    # :subject      => The entity performing the action.
    # :object       => The object the action is being applied to. Could be an
    #                    Person or Activity
    # :object_type  => How to interpret the object of the action.
    # :object_owner => The entity that owns the object of the action.
    # :when         => The Date when the activity took place.
    # :activity     => A reference to the original Activity.
    def parts_of_speech
      object_owner = nil
      object_owner = self.object.actor if self.object.respond_to?(:actor)
      object_owner = self.object if self.object.is_a?(Lotus::Person)
      object_owner = self.actor unless self.external_object_type

      {
        :verb         => self.verb || :post,
        :object       => self.object,
        :object_type  => self.type || :note,
        :object_owner => object_owner,
        :subject      => self.actor,
        :when         => self.updated,
        :activity     => self
      }
    end

    def self.find_from_notification(notification)
      Lotus::Activity.first(:uid => notification.activity.uid)
    end

    def self.create_from_notification!(notification)
      # We need to verify the payload
      identity = Lotus::Identity.discover!(notification.account)
      if notification.verified? identity.return_or_discover_public_key
        # Then add it to our feed in the appropriate place
        identity.discover_person!
        internal_activity = Lotus::Activity.find_from_notification(notification)

        # If it already exists, update it
        if internal_activity
          internal_activity.update_from_notification(notification, true)
        else
          internal_activity = Lotus::Activity.create!(notification.activity)
          internal_author = Lotus::Person.find_or_create_by_uid!(
                              notification.activity.actor.uid)

          internal_activity.actor = internal_author
          internal_activity.save
          internal_activity
        end
      else
        nil
      end
    end

    def update_from_notification(notification, force = false)
      # Do not allow another actor to change an existing activity
      if self.actor && self.actor.url != notification.activity.actor.url
        return nil
      end

      # We need to verify the payload
      identity = Lotus::Identity.discover!(notification.account)
      if force or notification.verified?(identity.return_or_discover_public_key)
        # Then add it to our feed in the appropriate place
        identity.discover_person!

        attributes = notification.activity.to_hash
        attributes.delete :uid

        self.update_attributes!(attributes)

        self
      else
        nil
      end
    end
  end
end

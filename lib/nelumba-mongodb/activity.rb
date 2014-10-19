module Nelumba
  class Activity
    include Nelumba::Object

    # All Activities originate from one particular Feed.
    key :feed_id, ObjectId
    belongs_to :feed, :class_name => 'Nelumba::Feed'

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

    # An Array of Persons that create the content in this Feed.
    key :actors_tuples, Array, :default => []

    # Determines what the action is acting upon.
    key :targets_tuples, Array, :default => []

    # Can attach an external object to this Activity.
    key :external_object_id, ObjectId
    key :external_object_type, String

    # Optionally, an object can be embedded inside an Activity.
    one :embedded_object, :class_name => "Nelumba::Comment", :polymorphic => true

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
      return unless !self.object.is_a?(Nelumba::Person) and
                    self.object.respond_to?(:parse_mentions)
      authors = self.object.parse_mentions do |username, domain|
        i = Identity.first(:username => /^#{Regexp.escape(username)}$/i)
        i.person if i
      end
      authors ||= []
      self.mentions_ids = authors.compact.map(&:id)
    end

    public

    def mentions?(author)
      if author.is_a? Nelumba::Identity
        author = author.person
      end

      self.mentions_ids.include? author.id
    end

    def self.article_by_id(id)
      self.object_by_id_and_type(id, Nelumba::Article)
    end

    def self.note_by_id(id)
      self.object_by_id_and_type(id, Nelumba::Note)
    end

    def self.object_by_id(id)
      oid = id
      if id.is_a? String
        oid = BSON::ObjectId.from_string(id)
      end

      activity = Nelumba::Activity.first("embedded_object._id" => oid)
      activity.object if activity
    end

    def self.object_by_id_and_type(id, type)
      obj = self.object_by_id(id)
      return obj if obj.is_a? type
      nil
    end

    # Intern, for consistency, standard object types.
    def type=(type)
      type = type.intern
      super type
    end

    # Set the actors.
    def actors=(obj)
      obj ||= []

      @actors = obj
      self[:actors_tuples] = obj.map do |obj|
        s = obj.class.to_s
        if s.start_with? "Nelumba::"
          s = s[9..-1]
        end
        [obj.id, s]
      end
    end

    # Get the actors.
    def actors
      return @actors if @actors

      @actors = self.actors_tuples.map do |tuple|
        id, type = *tuple
        return nil if type && !Nelumba.const_defined?(type)
        klass = Nelumba.const_get(type) if type
        klass.find_by_id(id) if klass && id
      end
    end

    # Set the actors.
    def targets=(obj)
      obj ||= []

      @targets = obj
      self[:targets_tuples] = obj.map do |obj|
        s = obj.class.to_s
        if s.start_with? "Nelumba::"
          s = s[9..-1]
        end
        [obj.id, s]
      end
    end

    # Get the targets.
    def targets
      return @targets if @targets

      @targets = self.targets_tuples.map do |tuple|
        id, type = *tuple
        return nil if type && !Nelumba.const_defined?(type)
        klass = Nelumba.const_get(type) if type
        klass.find_by_id(id) if klass && id
      end
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
        if self.external_object_type.start_with? "Nelumba::"
          self.external_object_type = self.external_object_type[9..-1]
        end
      end
      @object = obj
    end

    # Get the object.
    def object
      return @object if @object

      return @object = self.embedded_object if self.embedded_object
      return @object = nil unless self.external_object_type

      return nil if self.external_object_type && !Nelumba.const_defined?(self.external_object_type)
      klass = Nelumba.const_get(self.external_object_type) if self.external_object_type
      @object = klass.find_by_id(self.external_object_id) if klass && self.external_object_id
    end

    # Create a new Activity if the given Activity is not found by its id.
    def self.find_or_create_by_uid!(arg, *args)
      if arg.is_a? Nelumba::Activity
        uid = arg.uid
      else
        uid = arg[:uid]

        if arg[:author]
          arg[:author] = Person.find_or_create_by_uid!(arg[:author])
        end

        if arg.has_key? :author
          arg[:authors] = [arg[:author]]
          arg.delete :author
        end
      end

      activity = self.first(:uid => uid)
      return activity if activity

      begin
        if arg.is_a? Nelumba::Activity
          arg.save
        else
          activity = create!(arg, *args)
        end
      rescue
        activity = self.first(:uid => uid) or raise
      end

      activity
    end

    # Create a new Activity from a Hash of values or a Nelumba::Activity.
    def self.create!(*args)
      hash = {}
      if args.length > 0
        hash = args.shift
      end

      if hash.is_a? Nelumba::Activity
        hash = hash.to_hash

        hash.delete :authors
      end

      super hash, *args
    end

    # Create a new Activity from a Hash of values or a Nelumba::Activity.
    def self.create(*args)
      self.create! *args
    end

    # Discover a feed by the given activity location.
    def self.discover!(activity_identifier)
      activity = Nelumba::Activity.first(:url => activity_identifier)
      return activity if activity

      activity = Nelumba::Discover.activity(activity_identifier)
      return false unless activity

      existing = Activity.first(:uid => activity.uid)
      return existing if existing

      self.create!(activity)
    end

    def self.find_from_notification(notification)
      Nelumba::Activity.first(:uid => notification.activity.uid)
    end

    def self.create_from_notification!(notification)
      # We need to verify the payload
      identity = Nelumba::Identity.discover!(notification.account)
      if notification.verified? identity.return_or_discover_public_key
        # Then add it to our feed in the appropriate place
        identity.discover_person!
        internal_activity = Nelumba::Activity.find_from_notification(notification)

        # If it already exists, update it
        if internal_activity
          internal_activity.update_from_notification(notification, true)
        else
          internal_activity = Nelumba::Activity.create!(notification.activity)
          internal_author = Nelumba::Person.find_or_create_by_uid!(
                              notification.activity.actors.first.uid)

          internal_activity.actors = [internal_author]
          internal_activity.save
          internal_activity
        end
      else
        nil
      end
    end

    def update_from_notification(notification, force = false)
      # Do not allow another actor to change an existing activity
      if self.actors and self.actors.first and self.actors.first.url != notification.activity.actors.first.url
        return nil
      end

      # We need to verify the payload
      identity = Nelumba::Identity.discover!(notification.account)
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

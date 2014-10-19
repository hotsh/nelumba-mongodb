module Nelumba
  # Represents a typical social experience. This contains a feed of our
  # contributions, our consumable feed (timeline), our list of favorites,
  # a list of things that mention us and replies to us. It keeps track of
  # our social presence with who follows us and who we follow.
  class Person
    def initialize(*args); super(*args); end

    include MongoMapper::Document

    # Ensure writes happen
    safe

    # Every Person has a representation of their central Identity.
    one :identity, :class_name => 'Nelumba::Identity'

    # A Person MAY have an Authorization, if they are local
    one :authorization, :class_name => 'Nelumba::Authorization'

    # Each Person has an Avatar icon that identifies them.
    one :avatar, :class_name => 'Nelumba::Avatar'

    # Our contributions.
    key :activities_id,     ObjectId
    belongs_to :activities, :class_name => 'Nelumba::Feed'

    # The combined contributions of ourself and others we follow.
    key :timeline_id,     ObjectId
    belongs_to :timeline, :class_name => 'Nelumba::Feed'

    # The things we like.
    key :favorites_id,     ObjectId
    belongs_to :favorites, :class_name => 'Nelumba::Feed'

    # The things we shared.
    key :shared_id,     ObjectId
    belongs_to :shared, :class_name => 'Nelumba::Feed'

    # Replies to our stuff.
    key :replies_id,     ObjectId
    belongs_to :replies, :class_name => 'Nelumba::Feed'

    # Stuff that mentions us.
    key :mentions_id,     ObjectId
    belongs_to :mentions, :class_name => 'Nelumba::Feed'

    # The people that follow us.
    key  :following_ids, Array
    many :following,     :in => :following_ids, :class_name => 'Nelumba::Person'

    # Who is aggregating this feed.
    key  :followers_ids, Array
    many :followers,     :in => :followers_ids, :class_name => 'Nelumba::Person'

    # A unique identifier for this author.
    key :uid

    # A nickname for this author.
    key :nickname

    # A Hash containing a representation of (typically) the Person's real name:
    #   :formatted         => The full name of the contact
    #   :family_name       => The family name. "Last name" in Western contexts.
    #   :given_name        => The given name. "First name" in Western contexts.
    #   :middle_name       => The middle name.
    #   :honorific_prefix  => "Title" in Western contexts. (e.g. "Mr." "Mrs.")
    #   :honorific_suffix  => "Suffix" in Western contexts. (e.g. "Esq.")
    key :extended_name

    # A URI that identifies this author and can be used to access a
    # canonical representation of this structure.
    key :url

    # The email for this Person.
    key :email

    # The name for this Person.
    key :name

    # A Hash containing information about the organization this Person
    # represents:
    #   :name        => The name of the organization (e.g. company, school,
    #                   etc) This field is required. Will be used for sorting.
    #   :department  => The department within the organization.
    #   :title       => The title or role within the organization.
    #   :type        => The type of organization. Canonical values include
    #                   "job" or "school"
    #   :start_date  => A DateTime representing when the contact joined
    #                   the organization.
    #   :end_date    => A DateTime representing when the contact left the
    #                   organization.
    #   :location    => The physical location of this organization.
    #   :description => A free-text description of the role this contact
    #                   played in this organization.
    key :organization

    def organization
      hash = self[:organization] || {}

      hash.keys.each do |k|
        if ["name", "department", "title", "type", "start_date", "end_date",
            "description"].include?(k.to_s)
          hash[(k.to_sym rescue k)] =
            hash.delete(k)
        else
          hash.delete(k)
        end
      end

      hash
    end

    # A Hash containing the location of this Person:
    #   :formatted      => A formatted representating of the address. May
    #                     contain newlines.
    #   :street_address => The full street address. May contain newlines.
    #   :locality       => The city or locality component.
    #   :region         => The state or region component.
    #   :postal_code    => The zipcode or postal code component.
    #   :country        => The country name component.
    key :address

    def address
      hash = self[:address] || {}

      hash.keys.each do |k|
        if ["formatted", "street_address", "locality", "region", "country",
            "postal_code"].include?(k.to_s)
          hash[(k.to_sym rescue k)] =
            hash.delete(k)
        else
          hash.delete(k)
        end
      end

      hash
    end

    # A Hash containing the account information for this Person:
    #   :domain   => The top-most authoriative domain for this account. (e.g.
    #                "twitter.com") This is the primary field. Is required.
    #                Used for sorting.
    #   :username => An alphanumeric username, typically chosen by the user.
    #   :userid   => A user id, typically assigned, that uniquely refers to
    #                the user.
    key :account

    # The Person's gender.
    key :gender

    # The Person's requested pronouns.
    #
    # Contains at least one of the following:
    #   :plural     => Whether or not the Person is considered plural
    #   :personal   => The personal pronoun (xe)
    #   :possessive => The possessive pronoun (her)
    key :pronoun

    def pronoun
      hash = self[:pronoun] || {}

      hash.keys.each do |k|
        if ["personal", "possessive", "plural"].include?(k.to_s)
          hash[(k.to_sym rescue k)] =
            hash.delete(k)
        else
          hash.delete(k)
        end
      end

      hash
    end

    # A biographical note.
    key :note

    # The name the Person wishes to be used in display.
    key :display_name

    # The preferred username for the Person.
    key :preferred_username

    # A Date indicating the Person's birthday.
    key :birthday

    # A Date indicating an anniversary.
    key :anniversary

    # Automated Timestamps
    key :published, Time
    key :updated,   Time
    before_save :update_timestamps

    def update_timestamps
      now = Time.now.utc
      self[:published] ||= now if !persisted?
      self[:updated]     = now
    end

    # Create a new local Person
    def self.new_local(username, domain, port, ssl)
      person = Nelumba::Person.new(:nickname => username,
                                   :name => username,
                                   :display_name => username,
                                   :preferred_username => username)

      # Create url and uid for local Person
      person.url =
        "http#{ssl ? "s" : ""}://#{domain}#{port ? ":#{port}" : ""}/people/#{person.id}"
      person.uid = person.url

      # Create feeds for local Person
      person.activities = Nelumba::Feed.new(:person_id => person.id,
                                            :authors   => [person])
      person.activities_id = person.activities.id

      person.timeline   = Nelumba::Feed.new(:person_id => person.id,
                                            :authors   => [person])
      person.timeline_id = person.timeline.id

      person.shared     = Nelumba::Feed.new(:person_id => person.id,
                                            :authors   => [person])
      person.shared_id = person.shared.id

      person.favorites  = Nelumba::Feed.new(:person_id => person.id,
                                            :authors   => [person])
      person.favorites_id = person.favorites.id

      person.replies    = Nelumba::Feed.new(:person_id => person.id,
                                            :authors   => [person])
      person.replies_id = person.replies.id

      person.mentions   = Nelumba::Feed.new(:person_id => person.id,
                                            :authors   => [person])
      person.mentions_id = person.mentions.id

      person
    end

    # Create a new Person if the given Person is not found by its id.
    def self.find_or_create_by_uid!(arg, *args)
      if arg.is_a? Nelumba::Person
        uid = arg.uid

        arg = arg.to_hash
      else
        uid = arg[:uid]
      end

      person = self.first(:uid => uid)
      return person if person

      begin
        person = self.create!(arg, *args)
      rescue
        person = self.first(:uid => uid) or raise
      end

      person
    end

    # Updates so that we now follow the given Person.
    def follow!(author)
      if author.is_a? Nelumba::Identity
        author = author.person
      end

      # add the author from our list of followers
      self.following << author
      self.save

      # determine the feed to subscribe to
      self.timeline.follow! author.identity.outbox

      # tell local users that somebody on this server is following them.
      if author.local?
        author.followed_by! self
      end

      # Add the activity
      self.activities.post!(:verb                 => :follow,
                            :actor_id             => self.id,
                            :actor_type           => 'Person',
                            :external_object_id   => author.id,
                            :external_object_type => 'Person')
    end

    # Updates so that we do not follow the given Person.
    def unfollow!(author)
      if author.is_a? Nelumba::Identity
        author = author.person
      end

      # remove the person from our list of followers
      self.following_ids.delete(author.id)
      self.save

      # unfollow their timeline feed
      self.timeline.unfollow! author.identity.outbox

      # tell local users that somebody on this server has stopped following them.
      if author.local?
        author.unfollowed_by! self
      end

      # Add the activity
      self.activities.post!(:verb                 => :"stop-following",
                            :actor_id             => self.id,
                            :actor_type           => 'Person',
                            :external_object_id   => author.id,
                            :external_object_type => 'Person')
    end

    def follow?(author)
      if author.is_a? Nelumba::Identity
        author = author.person
      end

      self.following_ids.include? author.id
    end

    # Updates to show we are now followed by the given Person.
    def followed_by!(author)
      if author.is_a? Nelumba::Identity
        author = author.person
      end

      return if author.nil?

      # add them from our list
      self.followers << author
      self.save

      # determine their feed
      self.activities.followed_by! author.identity.inbox
    end

    # Updates to show we are not followed by the given Person.
    def unfollowed_by!(author)
      if author.is_a? Nelumba::Identity
        author = author.person
      end

      return if author.nil?

      # remove them from our list
      self.followers_ids.delete(author.id)
      self.save

      # remove their feed as a syndicate of our activities
      self.activities.unfollowed_by! author.identity.inbox
    end

    # Add the given Activity to our list of favorites.
    def favorite!(activity)
      self.favorites.repost! activity

      self.activities.post!(:verb                 => :favorite,
                            :actor_id             => self.id,
                            :actor_type           => 'Person',
                            :external_object_id   => activity.id,
                            :external_object_type => 'Activity')
    end

    # Remove the given Activity from our list of favorites.
    def unfavorite!(activity)
      self.favorites.delete! activity

      self.activities.post!(:verb                 => :unfavorite,
                            :actor_id             => self.id,
                            :actor_type           => 'Person',
                            :external_object_id   => activity.id,
                            :external_object_type => 'Activity')
    end

    # Add the given Activity to our list of those that mention us.
    def mentioned_by!(activity)
      self.mentions.repost! activity
    end

    # Add the given Activity to our list of those that are replies to our posts.
    def replied_by!(activity)
      self.replies.repost! activity
    end

    # Post a new Activity.
    def post!(activity)
      if activity.is_a? Hash
        activity["actor_id"] = self.id
        activity["actor_type"] = 'Person'

        activity["verb"] = :post unless activity["verb"] || activity[:verb]

        # Create a new activity
        activity = Activity.create!(activity)
      end

      self.activities.post! activity
      self.timeline.repost! activity

      # Check mentions and replies
      activity.mentions.each do |author|
        author.identity.post! activity
      end
    end

    # Repost an existing Activity.
    def share!(activity)
      self.timeline.repost! activity
      self.shared.repost!   activity

      self.activities.post!(:verb                 => :share,
                            :actor_id             => self.id,
                            :actor_type           => 'Person',
                            :external_object_id   => activity.id,
                            :external_object_type => 'Activity')
    end

    # Deliver an external Activity from somebody we follow.
    #
    # This goes in our timeline.
    def deliver!(activity)
      # Determine the original feed as duplicate it in our timeline
      author = Nelumba::Person.find(:id => activity.author.id)

      # Do not deliver if we do not follow the Person
      return false if author.nil?
      return false unless followings.include?(author)

      # We should know how to talk back to this person
      identity = Nelumba::Identity.find_by_author(author)
      return false if identity.nil?

      # Add to author's outbox feed
      identity.outbox.post! activity

      # Copy activity to timeline
      if activity.type == :note
        self.timeline.repost! activity
      end
    end

    # Receive an external Activity from somebody we don't know.
    #
    # Generally, will be a mention or reply. Shouldn't go into timeline.
    def receive!(activity)
    end

    # Deliver an activity from within the server
    def local_deliver!(activity)
      # If we follow, add to the timeline
      self.timeline.repost! activity if self.follow?(activity.actor)

      # Determine if it is a mention or reply and filter
      self.mentions.repost! activity if activity.mentions? self
    end

    # Updates our avatar with the given url.
    def update_avatar!(url)
      Nelumba::Avatar.from_url!(self, url, :sizes => [[48, 48]])
    end

    def remote?
      !self.local?
    end

    def local?
      !self.authorization.nil?
    end

    def self.sanitize_params(params)
      # Convert Symbols to Strings
      params.keys.each do |k|
        if k.is_a? Symbol
          params[k.to_s] = params[k]
          params.delete k
        end
      end

      # Delete unknown subkeys
      if params["extended_name"]
        unless params["extended_name"].is_a? Hash
          params.delete "extended_name"
        else
          params["extended_name"].keys.each do |k|
            if ["formatted", "given_name", "family_name", "honorific_prefix",
                "honorific_suffix", "middle_name"].include?(k.to_s)
              params["extended_name"][(k.to_sym rescue k)] =
                params["extended_name"].delete(k)
            else
              params["extended_name"].delete(k)
            end
          end
        end
      end

      if params["organization"]
        unless params["organization"].is_a? Hash
          params.delete "organization"
        else
          params["organization"].keys.each do |k|
            if ["name", "department", "title", "type", "start_date", "end_date",
                "description"].include?(k.to_s)
              params["organization"][(k.to_sym rescue k)] =
                params["organization"].delete(k)
            else
              params["organization"].delete(k)
            end
          end
        end
      end

      if params["pronoun"]
        unless params["pronoun"].is_a? Hash
          params.delete "pronoun"
        else
          params["pronoun"].keys.each do |k|
            if ["personal", "possessive", "plural"].include?(k.to_s)
              params["pronoun"][(k.to_sym rescue k)] =
                params["pronoun"].delete(k)
            else
              params["pronoun"].delete(k)
            end
          end
        end
      end

      if params["address"]
        unless params["address"].is_a? Hash
          params.delete "address"
        else
          params["address"].keys.each do |k|
            if ["formatted", "street_address", "locality", "region", "country",
                "postal_code"].include?(k.to_s)
              params["address"][(k.to_sym rescue k)] =
                params["address"].delete(k)
            else
              params["address"].delete(k)
            end
          end
        end
      end

      # Delete unknown keys
      params.keys.each do |k|
        unless self.keys.keys.include?(k)
          params.delete(k)
        end
      end

      # Delete immutable fields
      params.delete("_id")

      # Convert to symbols
      params.keys.each do |k|
        params[k.intern] = params[k]
        params.delete k
      end

      params
    end

    # Discover and populate the associated activity feed for this author.
    def discover_feed!
      Nelumba::Discover.feed(self.identity)
    end

    # Discover an Person by the given feed location or account.
    def self.discover!(author_identifier)
      # Did we already discover this Person?
      identity = Nelumba::Identity.find_by_identifier(author_identifier)
      return identity.person if identity

      # Discover the Identity
      identity = Nelumba::Discover.identity(author_identifier)
      return nil unless identity

      # Use their Identity to discover their feed and their Person
      feed = Nelumba::Discover.feed(identity)
      return nil unless feed

      feed.save

      identity = identity.to_hash.merge(:outbox => feed,
                                        :person_id => feed.authors.first.id)

      identity = Nelumba::Identity.create!(identity)
      identity.person
    end

    def to_xml(*args)
      self.to_atom
    end

    def self.find_by_username_and_domain(username, domain=nil)
      if username and domain
        i = Nelumba::Identity.first(:username => username,
                                    :domain   => domain)
      elsif username
        i = Nelumba::Identity.first(:username => username)
      else
        nil
      end

      i.person if i
    end
  end
end

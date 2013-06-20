# This represents a person. They act by creating Activities. These Activities
# go into Feeds. Feeds are collected into Aggregates.
module Lotus
  class Author
    def initialize(*args); super(*args); end

    include MongoMapper::Document

    # Every Author has a representation of their central Identity.
    one :identity, :class_name => 'Lotus::Identity'

    # Local accounts have a Person, but remote Authors will not.
    one :person, :class_name => 'Lotus::Person'

    # Whether or not this Author is a representation of somebody generating
    # content on our server.
    key :local

    # Each Author has an Avatar icon that identifies them.
    one :avatar, :class_name => 'Lotus::Avatar'

    # A unique identifier for this author.
    key :uid

    # A nickname for this author.
    key :nickname

    # A Hash containing a representation of (typically) the Author's real name:
    #   :formatted         => The full name of the contact
    #   :family_name       => The family name. "Last name" in Western contexts.
    #   :given_name        => The given name. "First name" in Western contexts.
    #   :middle_name       => The middle name.
    #   :honorific_prefix  => "Title" in Western contexts. (e.g. "Mr." "Mrs.")
    #   :honorific_suffix  => "Suffix" in Western contexts. (e.g. "Esq.")
    key :extended_name

    # A URI that identifies this author and can be used to access a
    # canonical representation of this structure.
    key :uri

    # The email for this Author.
    key :email

    # The name for this Author.
    key :name

    # A Hash containing information about the organization this Author
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

    # A Hash containing the location of this Author:
    #   :formatted      => A formatted representating of the address. May
    #                     contain newlines.
    #   :street_address => The full street address. May contain newlines.
    #   :locality       => The city or locality component.
    #   :region         => The state or region component.
    #   :postal_code    => The zipcode or postal code component.
    #   :country        => The country name component.
    key :address

    # A Hash containing the account information for this Author:
    #   :domain   => The top-most authoriative domain for this account. (e.g.
    #                "twitter.com") This is the primary field. Is required.
    #                Used for sorting.
    #   :username => An alphanumeric username, typically chosen by the user.
    #   :userid   => A user id, typically assigned, that uniquely refers to
    #                the user.
    key :account

    # The Author's gender.
    key :gender

    # A biographical note.
    key :note

    # The name the Author wishes to be used in display.
    key :display_name

    # The preferred username for the Author.
    key :preferred_username

    # A Date indicating the Author's birthday.
    key :birthday

    # A Date indicating an anniversary.
    key :anniversary

    timestamps!

    # Create a new Author if the given Author is not found by its uid.
    def self.find_or_create_by_uid!(arg, *args)
      if arg.is_a? Lotus::Author
        uid = arg.uid
      else
        uid = arg[:uid]
      end

      author = self.first(:uid => uid)
      return author if author

      begin
        author = self.create!(arg, *args)
      rescue
        author = self.first(:uid => uid) or raise
      end

      author
    end

    # Create a new Author from a Hash of values or a Lotus::Author.
    def self.create!(*args)
      hash = {}
      if args.length > 0
        hash = args.shift
      end

      if hash.is_a? Lotus::Author
        hash = hash.to_hash
      end

      hash = sanitize_params(hash)

      super(hash, *args)
    end

    # Create a new Author from a Hash of values or a Lotus::Author.
    def self.create(*args)
      self.create! *args
    end

    # Discover an Author by the given feed location or account.
    def self.discover!(author_identifier)
      # Did we already discover this Author?
      identity = Lotus::Identity.find_by_identifier(author_identifier)
      return identity.author if identity

      # Discover the Identity
      identity = Lotus.discover_identity(author_identifier)
      return false unless identity

      # Use their Identity to discover their feed and their Author
      feed = Lotus.discover_feed(identity)
      return false unless feed

      saved_feed = Feed.create!(feed)
      identity = identity.to_hash.merge(:outbox => saved_feed,
                                        :author => saved_feed.authors.first)
      Lotus::Identity.create!(identity).author
    end

    # Discover and populate the associated activity feed for this author.
    def discover_feed!
      Lotus.discover_feed(self.identity)
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

    # Determines the name to use to refer to this Author in a view.
    def short_name
      if self.display_name
        self.display_name
      elsif self.name
        self.name
      elsif self.preferred_username
        self.preferred_username
      elsif self.nickname
        self.nickname
      else
        self.uid
      end
    end

    def remote?
      !self.local
    end

    def local?
      self.local
    end

    # Updates our avatar with the given url.
    def update_avatar!(url)
      Lotus::Avatar.from_url!(self, url, :sizes => [[48, 48]])
    end
  end
end

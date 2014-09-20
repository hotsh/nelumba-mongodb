module Nelumba
  # This represents the information necessary to talk to an Person that is
  # external to our node, or it represents how to talk to us.
  # An Identity stores endpoints that are used to push or pull Activities from.
  class Identity
    def initialize(*args); super(*args); end

    include MongoMapper::Document

    # Ensure writes happen
    safe

    # public keys are good for 4 weeks
    PUBLIC_KEY_LEASE_DAYS = 28

    belongs_to :person, :class_name => 'Nelumba::Person'
    key :person_id, ObjectId

    key :username
    key :ssl
    key :domain

    # Identities have a public key that they use to sign salmon responses.
    #  Leasing: To ensure that keys can only be compromised in a small window but
    #  not require the server to retrieve a key per update, we store a lease.
    #  When the lease expires, and a notification comes, we retrieve the key.
    key :public_key
    key :public_key_lease, Date

    key :salmon_endpoint
    key :dialback_endpoint
    key :activity_inbox_endpoint
    key :activity_outbox_endpoint
    key :profile_page

    key :outbox_id, ObjectId
    belongs_to :outbox, :class_name => 'Nelumba::Feed'

    key :inbox_id, ObjectId
    belongs_to :inbox, :class_name => 'Nelumba::Feed'

    timestamps!

    # Extends the lease for the public key so it remains valid through the given
    # expiry period.
    def reset_key_lease
      self.public_key_lease = (DateTime.now + PUBLIC_KEY_LEASE_DAYS).to_date
    end

    # Extends the lease for the public key so it remains valid through the given
    # expiry period and saves.
    def reset_key_lease!
      reset_key_lease
      self.save
    end

    # Invalidates the public key
    def invalidate_public_key!
      self.public_key_lease = nil
      self.save
    end

    # Returns the valid public key
    def return_or_discover_public_key
      if self.public_key_lease.nil? or
         self.public_key_lease < DateTime.now.to_date
        # Lease has expired, get the public key again
        identity = Nelumba.discover_identity("acct:#{self.username}@#{self.domain}")

        self.public_key = identity.public_key
        reset_key_lease

        self.save
      end

      self.public_key
    end

    def self.new_local(person, username, domain, ssl, public_key)
      Nelumba::Identity.new(
        :username => username,
        :domain => domain,
        :ssl => ssl,
        :person_id => person.id,
        :public_key => public_key,
        :salmon_endpoint => "/people/#{person.id}/salmon",
        :dialback_endpoint => "/people/#{person.id}/dialback",
        :activity_inbox_endpoint => "/people/#{person.id}/inbox",
        :activity_outbox_endpoint => "/people/#{person.id}/outbox",
        :profile_page => "/people/#{person.id}",
        :outbox_id => person.activities.id,
        :inbox_id => person.timeline.id
      )
    end

    def self.find_by_identifier(identifier)
      matches  = identifier.match /^(?:.+\:)?([^@]+)@(.+)$/

      username = matches[1].downcase
      domain   = matches[2].downcase

      Nelumba::Identity.first(:username => username,
                            :domain => domain)
    end

    # Create a new Identity from a Hash of values or a Nelumba::Identity.
    # TODO: Create outbox and inbox aggregates to hold feed and sent activities
    def self.create!(*args)
      hash = {}
      if args.length > 0
        hash = args.shift
      end

      if hash.is_a? Nelumba::Identity
        hash = hash.to_hash
      end

      hash["username"] = hash["username"].downcase if hash["username"]
      hash["username"] = hash[:username].downcase if hash[:username]
      hash.delete :username

      hash["domain"] = hash["domain"].downcase if hash["domain"]
      hash["domain"] = hash[:domain].downcase if hash[:domain]
      hash.delete :domain

      hash = self.sanitize_params(hash)

      super hash, *args
    end

    # Create a new Identity from a Hash of values or a Nelumba::Identity.
    def self.create(*args)
      self.create! *args
    end

    # Ensure params has only valid keys
    def self.sanitize_params(params)
      params.keys.each do |k|
        if k.is_a? Symbol
          params[k.to_s] = params[k]
          params.delete k
        end
      end

      # Delete unknown keys
      params.keys.each do |k|
        unless self.keys.keys.include? k
          params.delete(k)
        end
      end

      # Delete immutable fields
      params.delete("_id")

      # Convert back to symbols
      params.keys.each do |k|
        params[k.intern] = params[k]
        params.delete k
      end

      params
    end

    # Discover an identity from the given user identifier.
    def self.discover!(account)
      identity = Nelumba::Identity.find_by_identifier(account)
      return identity if identity

      identity = Nelumba.discover_identity(account)
      return false unless identity

      self.create!(identity)
    end

    # Discover the associated author for this identity.
    def discover_person!
      Person.discover!("acct:#{self.username}@#{self.domain}")
    end

    # Post an existing activity to the inbox of the person that owns this Identity
    def post!(activity)
      if self.person.local?
        self.person.local_deliver! activity
      else
        self.inbox.repost! activity
      end
    end
  end
end

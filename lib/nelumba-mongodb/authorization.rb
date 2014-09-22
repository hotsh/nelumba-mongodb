module Nelumba
  # This represents how a Person can authenticate to act on our server.
  # This is attached to an Identity and a Person. Use this to allow an
  # Person to generate Activities on this server.
  class Authorization
    require 'bcrypt'
    require 'json'
    require 'nokogiri'

    include MongoMapper::Document

    # Ensure writes happen
    safe

    # An Authorization involves a Person.
    key :person_id,     ObjectId
    belongs_to :person, :class_name => 'Nelumba::Person'

    # Whether or not this authorization requires ssl
    key :ssl

    # The domain this authorization is registered for
    key :domain

    # The port authorization is tied to
    key :port

    # An Authorization involves an Identity.
    key :identity_id, ObjectId
    belongs_to :identity, :class_name => 'Nelumba::Identity'

    # You authorize with a username
    key :username,        String

    # A private key can verify that external information originated with this
    # account.
    key :private_key,     String

    # A password can authenticate you if you are manually signing in as a human
    # being. The password is hashed to prevent information leaking.
    key :hashed_password, String

    # You must have enough credentials to be able to log into the system:
    validates_presence_of :username
    validates_presence_of :identity
    validates_presence_of :hashed_password

    # Log modification
    timestamps!

    # Generate a Hash containing this person's LRDD meta info.
    def self.lrdd(username)
      username = username.match /(?:acct\:)?([^@]+)(?:@([^@]+))?$/
      username = username[1] if username
      if username.nil?
        return nil
      end

      # Find the person
      auth = Authorization.find_by_username(/#{Regexp.escape(username)}/i)
      return nil unless auth

      domain    = auth.identity.domain
      port      = auth.identity.port
      url       = "http#{auth.identity.ssl ? "s" : ""}://#{auth.identity.domain}#{port ? ":#{port}" : ""}"
      feed_id   = auth.identity.outbox.id
      person_id = auth.person.id

      {
        :subject => "acct:#{username}@#{domain}#{port ? ":#{port}" : ""}",
        :expires => "#{(Time.now.utc.to_date >> 1).xmlschema}Z",
        :aliases => [
          "#{url}#{auth.identity.profile_page}",
          "#{url}/feeds/#{feed_id}"
        ],
        :links => [
          {:rel  => "http://webfinger.net/rel/profile-page",
           :href => "#{url}/people/#{person_id}"},
          {:rel  => "http://schemas.google.com/g/2010#updates-from",
           :href => "#{url}/feeds/#{feed_id}"},
          {:rel  => "salmon",
           :href => "#{url}/people/#{person_id}/salmon"},
          {:rel  => "http://salmon-protocol.org/ns/salmon-replies",
           :href => "#{url}/people/#{person_id}/salmon"},
          {:rel  => "http://salmon-protocol.org/ns/salmon-mention",
           :href => "#{url}/people/#{person_id}/salmon"},
          {:rel  => "magic-public-key",
           :href => "data:application/magic-public-key,#{auth.identity.public_key}"}

          # TODO: ostatus subscribe
          #{:rel      => "http://ostatus.org/schema/1.0/subscribe",
          # :template => "#{url}/subscriptions?url={uri}&_method=post"}
        ]
      }
    end

    # Generate a String containing the json representation of this person's LRDD.
    def self.jrd(username)
      lrdd = self.lrdd(username)
      return nil if lrdd.nil?

      lrdd.to_json
    end

    # Generate a String containing the XML representaton of this person's LRDD.
    def self.xrd(username)
      lrdd = self.lrdd(username)
      return nil if lrdd.nil?

      # Build xml
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.XRD("xmlns"     => 'http://docs.oasis-open.org/ns/xri/xrd-1.0',
                "xmlns:xsi" => 'http://www.w3.org/2001/XMLSchema-instance') do
          xml.Subject lrdd[:subject]
          xml.Expires lrdd[:expires]

          lrdd[:aliases].each do |alias_name|
            xml.Alias alias_name
          end

          lrdd[:links].each do |link|
            xml.Link link
          end
        end
      end

      # Output
      builder.to_xml
    end

    # Create a hash of the password.
    def self.hash_password(password)
      BCrypt::Password.create(password, :cost => Nelumba::BCRYPT_ROUNDS)
    end

    # Determine if the given password matches the account.
    def authenticated?(password)
      BCrypt::Password.new(hashed_password) == password
    end

    # :nodoc: Do not allow the password to be set at any cost.
    def password=(value)
    end

    # Cleanup any unexpected keys.
    def self.sanitize_params(params)
      # Convert Symbols to Strings
      params.keys.each do |k|
        if k.is_a? Symbol
          params[k.to_s] = params[k]
          params.delete k
        end
      end

      # Delete unknown keys
      params.keys.each do |k|
        unless self.keys.keys.map.include?(k)
          params.delete(k)
        end
      end

      # Delete immutable fields
      params.delete("id")
      params.delete("_id")

      # Convert to symbols
      params.keys.each do |k|
        params[k.intern] = params[k]
        params.delete k
      end

      params
    end

    # Create a new Authorization.
    def initialize(*args)
      params = {}
      params = args.shift if args.length > 0

      params["password"] = params[:password] if params[:password]
      params.delete :password

      params["hashed_password"] = Authorization.hash_password(params["password"])
      params.delete "password"

      params = Authorization.sanitize_params(params)

      person = Nelumba::Person.new_local(params[:username],
                                         params[:domain],
                                         params[:port],
                                         params[:ssl])
      person.save
      params[:person_id] = person.id

      keypair = Nelumba::Crypto.new_keypair
      params[:private_key] = keypair.private_key

      identity = Nelumba::Identity.new_local(person,
                                             params[:username],
                                             params[:domain],
                                             params[:port],
                                             params[:ssl],
                                             keypair.public_key)
      identity.save
      params[:identity_id] = identity.id

      params[:person] = person
      params[:identity] = identity

      super params, *args
    end
  end
end

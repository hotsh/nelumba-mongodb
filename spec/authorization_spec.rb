require_relative 'helper'

require 'xml'

module Lotus
  BCRYPT_ROUNDS = 1234
end

def create_authorization(params)
  params["domain"] ||= "www.example.com"

  Lotus::Authorization.stubs(:hash_password).returns("hashed")

  keypair = Struct.new(:public_key, :private_key).new("PUBKEY", "PRIVKEY")
  Lotus::Crypto.stubs(:new_keypair).returns(keypair)

  authorization = Lotus::Authorization.new(params)

  authorization
end

describe Lotus::Authorization do
  describe "Schema" do
    it "should have a person_id" do
      Lotus::Authorization.keys.keys.must_include "person_id"
    end

    it "should have an identity_id" do
      Lotus::Authorization.keys.keys.must_include "identity_id"
    end

    it "should belong to a identity" do
      Lotus::Authorization.belongs_to?(:identity).must_equal true
    end

    it "should have a username" do
      Lotus::Authorization.keys.keys.must_include "username"
    end

    it "should have a private_key" do
      Lotus::Authorization.keys.keys.must_include "private_key"
    end

    it "should have a hashed_password" do
      Lotus::Authorization.keys.keys.must_include "hashed_password"
    end

    it "should have an updated_at" do
      Lotus::Authorization.keys.keys.must_include "updated_at"
    end

    it "should have a created_at" do
      Lotus::Authorization.keys.keys.must_include "created_at"
    end

    it "should not have a password" do
      Lotus::Authorization.keys.keys.wont_include "password"
    end
  end

  describe "create" do
    before do
      Lotus::Authorization.stubs(:hash_password).returns("hashed")

      keypair = Struct.new(:public_key, :private_key).new("PUBKEY", "PRIVKEY")
      Lotus::Crypto.stubs(:new_keypair).returns(keypair)
    end

    it "should create a person attached to this authorization" do
      person = Lotus::Person.new_local "wilkie", "www.example.com", true
      Lotus::Person.expects(:new_local).returns(person)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should save the person attached to this authorization" do
      person = Lotus::Person.new_local "wilkie", "www.example.com", true
      Lotus::Person.stubs(:new_local).returns(person)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)

      Lotus::Person.first(:id => person.id).activities_id.wont_equal nil
    end

    it "should create a Person with the given username" do
      person = Lotus::Person.new_local "wilkie", "www.example.com", true
      Lotus::Person.expects(:new_local)
                   .with("wilkie", anything, anything)
                   .returns(person)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should create a Person with the given domain" do
      person = Lotus::Person.new_local "wilkie", "www.example.com", true
      Lotus::Person.expects(:new_local)
                   .with(anything, "www.example.com", anything)
                   .returns(person)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should create a Person with the given ssl requirements" do
      person = Lotus::Person.new_local "wilkie", "www.example.com", true
      Lotus::Person.expects(:new_local)
                   .with(anything, anything, true)
                   .returns(person)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should create an Lotus::Identity" do
      Lotus::Identity.expects(:new_local)
                     .returns(Lotus::Identity.new)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should create an Lotus::Identity with the generated public key" do
      Lotus::Identity.expects(:new_local)
                     .with(anything, anything, anything, anything, "PUBKEY")
                     .returns(Lotus::Identity.new)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should create an Lotus::Identity with the given username" do
      Lotus::Identity.expects(:new_local)
                     .with(anything, "wilkie", anything, anything, anything)
                     .returns(Lotus::Identity.new)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should create an Lotus::Identity with the given domain" do
      Lotus::Identity.expects(:new_local)
             .with(anything, anything, "www.example.com", anything, anything)
             .returns(Lotus::Identity.new)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should create an Lotus::Identity with the given ssl requirements" do
      Lotus::Identity.expects(:new_local)
                     .with(anything, anything, anything, true, anything)
                     .returns(Lotus::Identity.new)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should create an Lotus::Identity with the new person's author" do
      person = Lotus::Person.new_local "wilkie", "www.example.com", true
      Lotus::Person.stubs(:new_local).returns(person)

      Lotus::Identity.expects(:new_local)
                     .with(person, anything, anything, anything, anything)
                     .returns(Lotus::Identity.new)

      Lotus::Authorization.new("username" => "wilkie",
                               "password" => "foobar",
                               "domain" => "www.example.com",
                               "ssl" => true)
    end

    it "should associate a new Lotus::Identity with this Lotus::Authorization" do
      person = Lotus::Person.new_local "wilkie", "www.example.com", true
      Lotus::Person.stubs(:new_local).returns(person)

      auth = Lotus::Authorization.new("username" => "wilkie",
                                      "password" => "foobar",
                                      "domain" => "www.example.com",
                                      "ssl" => true)

      auth.identity_id.must_equal person.identity.id
    end

    it "should store the private key" do
      auth = Lotus::Authorization.new("username" => "wilkie",
                                      "password" => "foobar",
                                      "domain" => "www.example.com",
                                      "ssl" => true)

      auth.private_key.must_equal "PRIVKEY"
    end
  end

  describe "lrdd" do
    it "returns nil when the username cannot be found" do
      Lotus::Authorization.stubs(:find_by_username).returns(nil)
      Lotus::Authorization.lrdd("bogus@www.example.com").must_equal nil
    end

    it "should contain a subject matching their webfinger" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:subject]
                   .must_equal "acct:wilkie@www.example.com"
    end

    it "should contain an alias to the profile" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:aliases]
        .must_include "http://www.example.com/people/#{authorization.person.id}"
    end

    it "should contain an alias to the profile" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:aliases]
        .must_include "http://www.example.com/people/#{authorization.person.id}"
    end

    it "should contain an alias to the feed" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:aliases].must_include(
        "http://www.example.com/feeds/#{authorization.identity.outbox.id}")
    end

    it "should contain profile-page link" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      person_id = authorization.person.id

      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:links]
        .must_include({:rel  => "http://webfinger.net/rel/profile-page",
                       :href => "http://www.example.com/people/#{person_id}"})
    end

    it "should contain updates-from link" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      feed_id = authorization.identity.outbox.id

      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:links]
        .must_include({:rel  => "http://schemas.google.com/g/2010#updates-from",
                       :href => "http://www.example.com/feeds/#{feed_id}"})
    end

    it "should contain salmon link" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      person_id = authorization.person.id

      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:links]
        .must_include(:rel  => "salmon",
                      :href => "http://www.example.com/people/#{person_id}/salmon")
    end

    it "should contain salmon-replies link" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      person_id = authorization.person.id

      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:links]
        .must_include(:rel  => "http://salmon-protocol.org/ns/salmon-replies",
                      :href => "http://www.example.com/people/#{person_id}/salmon")
    end

    it "should contain salmon-mention link" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      person_id = authorization.person.id

      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:links]
        .must_include(:rel  => "http://salmon-protocol.org/ns/salmon-mention",
                      :href => "http://www.example.com/people/#{person_id}/salmon")
    end

    it "should contain magic-public-key link" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")
      person_id = authorization.person.id

      authorization.identity.public_key = "PUBLIC_KEY"

      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:links]
        .must_include(:rel  => "magic-public-key",
                      :href => "data:application/magic-public-key,PUBLIC_KEY")
    end

    it "should contain an expires link that is 1 month away from retrieval" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")

      check_date = Date.new(2012, 1, 1)
      Date.any_instance.expects(:>>).with(1).returns(check_date)

      Lotus::Authorization.stubs(:find_by_username).returns(authorization)
      Lotus::Authorization.lrdd("wilkie@www.example.com")[:expires].must_equal(
        "#{check_date.xmlschema}Z")
    end
  end

  describe "jrd" do
    it "should simply take the lrdd and run to_json" do
      lrdd_hash = {}
      Lotus::Authorization.stubs(:lrdd).with("wilkie@www.example.com").returns(lrdd_hash)
      lrdd_hash.stubs(:to_json).returns("JSON")

      Lotus::Authorization.jrd("wilkie@www.example.com").must_equal "JSON"
    end

    it "should return nil when lrdd returns nil" do
      Lotus::Authorization.stubs(:lrdd).returns(nil)
      Lotus::Authorization.jrd("bogus@www.example.com").must_equal nil
    end
  end

  describe "xrd" do
    before do
      @authorization = create_authorization("username" => "wilkie",
                                            "password" => "foobar")

      Lotus::Authorization.stubs(:lrdd).returns(:subject => "Subject",
                                         :expires => "Date",
                                         :aliases => ["alias_a",
                                                      "alias_b"],
                                         :links   => [
                                           {:rel  => "a rel",
                                            :href => "a href"},
                                           {:rel  => "b rel",
                                            :href => "b href"}])

      @xrd = Lotus::Authorization.xrd("wilkie@www.example.com")

      @xml = XML::Parser.string(@xrd).parse
    end

    it "should return nil when lrdd returns nil" do
      Lotus::Authorization.stubs(:lrdd).returns(nil)
      Lotus::Authorization.xrd("bogus@www.example.com").must_equal nil
    end

    it "should publish a version of 1.0" do
      @xrd.must_match /^<\?xml[^>]*\sversion="1\.0"/
    end

    it "should encode in utf-8" do
      @xrd.must_match /^<\?xml[^>]*\sencoding="UTF-8"/
    end

    it "should contain the XRD namespace" do
      @xml.root.namespaces
               .find_by_href('http://docs.oasis-open.org/ns/xri/xrd-1.0').to_s
               .must_equal 'http://docs.oasis-open.org/ns/xri/xrd-1.0'
    end

    it "should contain the xsi namespace" do
      @xml.root.namespaces
               .find_by_prefix('xsi').to_s
               .must_equal 'xsi:http://www.w3.org/2001/XMLSchema-instance'
    end

    it "should contain the <Subject>" do
      @xml.root.find_first('xmlns:Subject',
                           'xmlns:http://docs.oasis-open.org/ns/xri/xrd-1.0')
        .content.must_equal Lotus::Authorization.lrdd("wilkie@www.example.com")[:subject]
    end

    it "should contain the <Expires>" do
      @xml.root.find_first('xmlns:Expires',
                           'xmlns:http://docs.oasis-open.org/ns/xri/xrd-1.0')
        .content.must_equal Lotus::Authorization.lrdd("wilkie@www.example.com")[:expires]
    end

    it "should contain the <Alias> tags" do
      aliases = Lotus::Authorization.lrdd("wilkie@www.example.com")[:aliases]
      @xml.root.find('xmlns:Alias',
                  'xmlns:http://docs.oasis-open.org/ns/xri/xrd-1.0').each do |t|
        index = aliases.index(t.content)
        index.wont_equal nil

        aliases.delete_at index
      end
    end

    it "should contain the <Link> tags" do
      links = Lotus::Authorization.lrdd("wilkie@www.example.com")[:links]
      @xml.root.find('xmlns:Link',
                  'xmlns:http://docs.oasis-open.org/ns/xri/xrd-1.0').each do |t|
        link = {:rel  => t.attributes.get_attribute('rel').value,
                :href => t.attributes.get_attribute('href').value}
        index = links.index(link)
        index.wont_equal nil

        links.delete_at index
      end
    end
  end

  describe "hash_password" do
    it "should call bcrypt with the application specified number of rounds" do
      BCrypt::Password.expects(:create).with(anything, has_entry(:cost, 1234))
      Lotus::Authorization.hash_password("foobar")
    end

    it "should call bcrypt with the given password" do
      BCrypt::Password.expects(:create).with("foobar", anything)
      Lotus::Authorization.hash_password("foobar")
    end

    it "should return the hashed password" do
      BCrypt::Password.expects(:create).returns("hashed!")
      Lotus::Authorization.hash_password("foobar").must_equal "hashed!"
    end
  end

  describe "#authenticated?" do
    it "should compare the given password with the stored password" do
      authorization = create_authorization("username" => "wilkie",
                                           "password" => "foobar")

      checker = stub('String')
      BCrypt::Password.stubs(:new).with("hashed").returns(checker)

      checker.expects(:==).with("foobar")
      authorization.authenticated?("foobar")
    end
  end

  describe "sanitize_params" do
    it "should allow Lotus::Authorization keys" do
      hash = {}
      Lotus::Authorization.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k] = "foobar"
      end

      hash = Lotus::Authorization.sanitize_params(hash)

      Lotus::Authorization.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k.intern].must_equal "foobar"
      end
    end

    it "should remove password key" do
      hash = {"password" => "foobar"}
      hash = Lotus::Authorization.sanitize_params(hash)
      hash.keys.wont_include :password
    end

    it "should convert strings to symbols" do
      hash = {}
      Lotus::Authorization.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k] = "foobar"
      end

      hash = Lotus::Authorization.sanitize_params(hash)

      Lotus::Authorization.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k.intern].must_equal "foobar"
      end
    end

    it "should not allow _id" do
      hash = {"_id" => "bogus"}
      hash = Lotus::Authorization.sanitize_params(hash)
      hash.keys.wont_include :_id
    end

    it "should not allow arbitrary keys" do
      hash = {:bogus => "foobar"}

      hash = Lotus::Authorization.sanitize_params(hash)

      hash.keys.wont_include :bogus
    end
  end
end

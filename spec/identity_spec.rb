require_relative 'helper'

describe Lotus::Identity do
  describe "Schema" do
    it "should have a username" do
      Lotus::Identity.keys.keys.must_include "username"
    end

    it "should have an ssl field" do
      Lotus::Identity.keys.keys.must_include "ssl"
    end

    it "should have a domain" do
      Lotus::Identity.keys.keys.must_include "domain"
    end

    it "should have a public_key" do
      Lotus::Identity.keys.keys.must_include "public_key"
    end

    it "should have a salmon_endpoint" do
      Lotus::Identity.keys.keys.must_include "salmon_endpoint"
    end

    it "should have a dialback_endpoint" do
      Lotus::Identity.keys.keys.must_include "dialback_endpoint"
    end

    it "should have an activity_inbox_endpoint" do
      Lotus::Identity.keys.keys.must_include "activity_inbox_endpoint"
    end

    it "should have an activity_outbox_endpoint" do
      Lotus::Identity.keys.keys.must_include "activity_inbox_endpoint"
    end

    it "should have a profile_page" do
      Lotus::Identity.keys.keys.must_include "profile_page"
    end

    it "should have an outbox_id" do
      Lotus::Identity.keys.keys.must_include "outbox_id"
    end

    it "should have a created_at" do
      Lotus::Identity.keys.keys.must_include "created_at"
    end

    it "should have a updated_at" do
      Lotus::Identity.keys.keys.must_include "updated_at"
    end
  end

  describe "find_by_identifier" do
    it "should return nil when the identifier cannot be found" do
      Lotus::Identity.create!(:username => "bogus",
                       :domain   => "rstat.us")

      Lotus::Identity.find_by_identifier("wilkie@rstat.us").must_equal nil
    end

    it "should return the Lotus::Identity when the identifier is found" do
      identity = Lotus::Identity.create!(:username => "wilkie",
                                  :domain   => "rstat.us")

      Lotus::Identity.find_by_identifier("wilkie@rstat.us")
        .id.must_equal identity.id
    end

    it "should search without case sensitivity of the username" do
      identity = Lotus::Identity.create!(:username => "WilkiE",
                                  :domain   => "rstat.us")

      Lotus::Identity.find_by_identifier("wiLkIe@rstat.us")
        .id.must_equal identity.id
    end

    it "should search without case sensitivity of the domain" do
      identity = Lotus::Identity.create!(:username => "wilkie",
                                  :domain   => "rStat.uS")

      Lotus::Identity.find_by_identifier("wilkie@rstAt.Us")
        .id.must_equal identity.id
    end

    it "should ignore url scheme" do
      identity = Lotus::Identity.create!(:username => "wilkie",
                                  :domain   => "rstat.us")

      Lotus::Identity.find_by_identifier("acct:wilkie@rstat.us")
        .id.must_equal identity.id
    end
  end

  describe "create!" do
    it "should take a Lotus::Identity" do
      identity = Lotus::Identity.new
      identity.stubs(:to_hash).returns({"username" => "wilkie"})

      Lotus::Identity.create!(identity).username.must_equal "wilkie"
    end

    it "should allow a hash of values" do
      Lotus::Identity.create!("username" => "wilkie").username.must_equal "wilkie"
    end

    it "should not store arbitrary fields" do
      Lotus::Identity.create!(:foobar => "bar").serializable_hash.keys
        .wont_include "foobar"
    end
  end

  describe "sanitize_params" do
    it "should allow Lotus::Identity keys" do
      hash = {}
      Lotus::Identity.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k.to_str] = "foobar"
      end

      hash = Lotus::Identity.sanitize_params(hash)

      Lotus::Identity.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k.intern].must_equal "foobar"
      end
    end

    it "should convert strings to symbols" do
      hash = {}
      Lotus::Identity.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k.to_str] = "foobar"
      end

      hash = Lotus::Identity.sanitize_params(hash)

      Lotus::Identity.keys.keys.each do |k|
        next if ["_id"].include? k
        hash[k.intern].must_equal "foobar"
      end
    end

    it "should not allow _id" do
      hash = {"_id" => "bogus"}
      hash = Lotus::Identity.sanitize_params(hash)
      hash.keys.wont_include "_id"
    end

    it "should not allow arbitrary keys" do
      hash = {:bogus => "foobar"}

      hash = Lotus::Identity.sanitize_params(hash)

      hash.keys.wont_include :bogus
    end
  end

  describe "discover!" do
    it "should use Lotus to discover an identity given the account" do
      Lotus.expects(:discover_identity)

      Lotus::Identity.discover!("wilkie@rstat.us")
    end

    it "should simply report the identity if already known" do
      identity = Lotus::Identity.create(:username => "wilkie",
                                 :domain => "rstat.us")
      Lotus.expects(:discover_identity).never

      Lotus::Identity.discover!("wilkie@rstat.us").id.must_equal identity.id
    end

    it "should create the Lotus::Identity upon discovery" do
      identity = Lotus::Identity.new
      Lotus.stubs(:discover_identity).returns(identity)

      Lotus::Identity.stubs(:create!).with(identity)

      Lotus::Identity.discover!("wilkie@rstat.us")
    end

    it "should return the created Lotus::Identity upon discovery" do
      identity = Lotus::Identity.new
      Lotus.stubs(:discover_identity).returns(identity)

      Lotus::Identity.stubs(:create!).with(identity).returns("new identity")

      Lotus::Identity.discover!("wilkie@rstat.us").must_equal "new identity"
    end
  end

  describe "discover_person!" do
    it "should discover the author through Lotus::Person" do
      identity = Lotus::Identity.new(:username => "wilkie", :domain => "rstat.us")
      Lotus::Person.expects(:discover!).with("acct:wilkie@rstat.us").returns("author")

      identity.discover_person!
    end
  end

  describe "return_or_discover_public_key" do
    it "should return public_key when public_key_lease is not expired" do
      days = Lotus::Identity::PUBLIC_KEY_LEASE_DAYS
      identity = Lotus::Identity.new(:public_key => "KEY",
                              :public_key_lease => (DateTime.now+days).to_date,
                              :username => "wilkie",
                              :domain => "rstat.us")

      Lotus.expects(:discover_identity).never

      identity.return_or_discover_public_key.must_equal "KEY"
    end

    it "should discover the public key when the public_key_lease has expired" do
      identity = Lotus::Identity.new(:public_key => "BOGUS",
                              :public_key_lease => (DateTime.now-1).to_date,
                              :username => "wilkie",
                              :domain => "rstat.us")

      identity.expects(:reset_key_lease)

      lotus_identity = mock('Lotus::Identity')
      lotus_identity.stubs(:public_key).returns("KEY")
      Lotus.expects(:discover_identity).returns(lotus_identity)

      identity.return_or_discover_public_key.must_equal "KEY"
    end

    it "should discover the public key when the public_key_lease is nil" do
      identity = Lotus::Identity.new(:public_key => "BOGUS",
                              :public_key_lease => nil,
                              :username => "wilkie",
                              :domain => "rstat.us")

      identity.expects(:reset_key_lease)

      lotus_identity = mock('Lotus::Identity')
      lotus_identity.stubs(:public_key).returns("KEY")
      Lotus.expects(:discover_identity).returns(lotus_identity)

      identity.return_or_discover_public_key.must_equal "KEY"
    end
  end
end

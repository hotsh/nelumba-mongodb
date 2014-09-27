require_relative 'helper'

describe Nelumba::Activity do
  describe "Schema" do
    it "should have a feed_id" do
      Nelumba::Activity.keys.keys.must_include "feed_id"
    end

    it "should have a uid" do
      Nelumba::Activity.keys.keys.must_include "uid"
    end

    it "should have a url" do
      Nelumba::Activity.keys.keys.must_include "url"
    end

    it "should have a type" do
      Nelumba::Activity.keys.keys.must_include "type"
    end

    it "should have an actor_id" do
      Nelumba::Activity.keys.keys.must_include "actor_id"
    end

    it "should have an actor_type" do
      Nelumba::Activity.keys.keys.must_include "actor_type"
    end

    it "should have a target_id" do
      Nelumba::Activity.keys.keys.must_include "target_id"
    end

    it "should have a target_type" do
      Nelumba::Activity.keys.keys.must_include "target_type"
    end

    it "should have an external_object_id" do
      Nelumba::Activity.keys.keys.must_include "external_object_id"
    end

    it "should have an external_object_type" do
      Nelumba::Activity.keys.keys.must_include "external_object_type"
    end

    it "should have a title" do
      Nelumba::Activity.keys.keys.must_include "title"
    end

    it "should have a content" do
      Nelumba::Activity.keys.keys.must_include "content"
    end

    it "should have a source" do
      Nelumba::Activity.keys.keys.must_include "source"
    end

    it "should have an in_reply_to_ids" do
      Nelumba::Activity.keys.keys.must_include "in_reply_to_ids"
    end

    it "should have an replies_ids" do
      Nelumba::Activity.keys.keys.must_include "replies_ids"
    end

    it "should have an shares_ids" do
      Nelumba::Activity.keys.keys.must_include "shares_ids"
    end

    it "should have an mentions_ids" do
      Nelumba::Activity.keys.keys.must_include "mentions_ids"
    end

    it "should have an likes_ids" do
      Nelumba::Activity.keys.keys.must_include "likes_ids"
    end

    it "should have a published" do
      Nelumba::Activity.keys.keys.must_include "published"
    end

    it "should have a updated" do
      Nelumba::Activity.keys.keys.must_include "updated"
    end
  end

  describe "create!" do
    it "should assign default uid" do
      activity = Nelumba::Activity.new
      activity.run_callbacks :create

      activity.uid.must_equal "/activities/#{activity.id}"
    end

    it "should assign default url" do
      activity = Nelumba::Activity.new
      activity.run_callbacks :create

      activity.url.must_equal "/activities/#{activity.id}"
    end
  end

  describe "#actor=" do
    it "should assign actor_id to the id of a given Nelumba::Person" do
      activity = Nelumba::Activity.new
      actor = Nelumba::Person.new

      activity.actor = actor

      activity.actor_id.must_equal actor.id
    end

    it "should assign actor_id to the id of a given Nelumba::Activity" do
      activity = Nelumba::Activity.new
      actor = Nelumba::Activity.new

      activity.actor = actor

      activity.actor_id.must_equal actor.id
    end

    it "should assign actor_type appropriately for a given Nelumba::Person" do
      activity = Nelumba::Activity.new
      actor = Nelumba::Person.new

      activity.actor = actor

      activity.actor_type.must_equal "Person"
    end

    it "should assign actor_type appropriately for a given Nelumba::Activity" do
      activity = Nelumba::Activity.new
      actor = Nelumba::Activity.new

      activity.actor = actor

      activity.actor_type.must_equal "Activity"
    end

    it "should return the given object instead of querying the database" do
      activity = Nelumba::Activity.new
      actor = Nelumba::Activity.new

      activity.actor = actor

      activity.actor.id.must_equal actor.id
    end
  end

  describe "#actor" do
    it "should retrieve a stored Nelumba::Person" do
      actor = Nelumba::Person.create
      activity = Nelumba::Activity.new(:actor_id => actor.id,
                                       :actor_type => "Person")

      activity.actor.id.must_equal actor.id
      activity.actor.class.must_equal Nelumba::Person
    end

    it "should retrieve a stored Nelumba::Activity" do
      actor = Nelumba::Activity.create
      activity = Nelumba::Activity.new(:actor_id => actor.id,
                                       :actor_type => "Activity")

      activity.actor.id.must_equal actor.id
      activity.actor.class.must_equal Nelumba::Activity
    end
  end

  describe "find_or_create_by_uid!" do
    it "should return the existing Nelumba::Activity" do
      activity = Nelumba::Activity.create!(:uid => "UID",
                                           :url => "URL")

      Nelumba::Activity.find_or_create_by_uid!(:uid => "UID").uid.must_equal activity.uid
    end

    it "should return the existing Nelumba::Activity via Nelumba::Activity" do
      activity = Nelumba::Activity.create!(:uid => "UID",
                                           :url => "URL")

      nelumba_activity = Nelumba::Activity.new(:uid => "UID")

      Nelumba::Activity.find_or_create_by_uid!(nelumba_activity).uid.must_equal activity.uid
    end

    it "should create when the Nelumba::Activity is not found" do
      Nelumba::Activity.expects(:create!).with({:uid => "UID"})
      Nelumba::Activity.find_or_create_by_uid!(:uid => "UID")
    end

    it "should save the given Nelumba::Activity when not found" do
      nelumba_activity = Nelumba::Activity.new
      nelumba_activity.stubs(:id).returns("UID")

      nelumba_activity.expects(:save)
      Nelumba::Activity.find_or_create_by_uid!(nelumba_activity)
    end

    it "should create a Nelumba::Activity from a hash when not found" do
      hash = {:uid => "UID"}

      Nelumba::Activity.expects(:create!).with(hash)
      Nelumba::Activity.find_or_create_by_uid!(hash)
    end

    it "should account for race condition where entry was created after find" do
      Nelumba::Activity.stubs(:first).returns(nil).then.returns("activity")
      Nelumba::Activity.stubs(:create!).raises("")
      Nelumba::Activity.find_or_create_by_uid!(:uid => "UID").must_equal "activity"
    end

    it "should save the attached author found in the given hash" do
      author_hash = {:uid => "PERSON_UID"}
      hash = {:uid => "UID", :author => author_hash}

      Nelumba::Person.expects(:find_or_create_by_uid!).with(author_hash)
      Nelumba::Activity.find_or_create_by_uid!(hash)
    end
  end

  describe "discover!" do
    it "should call out to Nelumba to discover the given Nelumba::Activity" do
      Nelumba.expects(:discover_activity).with("activity_url")
      Nelumba::Activity.discover!("activity_url")
    end

    it "should return false when the Nelumba::Activity cannot be discovered" do
      Nelumba.stubs(:discover_activity).returns(false)
      Nelumba::Activity.discover!("activity_url").must_equal false
    end

    it "should return the existing Nelumba::Activity if it is found by url" do
      activity = Nelumba::Activity.create!(:url => "activity_url",
                                  :uid => "uid")
      Nelumba::Activity.discover!("activity_url").id.must_equal activity.id
    end

    it "should return the existing Nelumba::Activity if uid matches" do
      activity = Nelumba::Activity.create!(:url => "activity_url",
                                         :uid => "ID")

      nelumba_activity = Nelumba::Activity.new(:uid => "ID")

      Nelumba.stubs(:discover_activity).returns(nelumba_activity)
      Nelumba::Activity.discover!("alternative_url").uid.must_equal activity.uid
    end

    it "should create a new Nelumba::Activity from the discovered Nelumba::Activity" do
      nelumba_activity = Nelumba::Activity.new
      nelumba_activity.stubs(:id).returns("ID")

      Nelumba.stubs(:discover_activity).returns(nelumba_activity)
      Nelumba::Activity.expects(:create!).returns("new_activity")
      Nelumba::Activity.discover!("alternative_url")
    end

    it "should return the new Nelumba::Activity from the discovered Nelumba::Activity" do
      nelumba_activity = Nelumba::Activity.new
      nelumba_activity.stubs(:id).returns("ID")

      Nelumba.stubs(:discover_activity).returns(nelumba_activity)
      Nelumba::Activity.stubs(:create!).returns("new_activity")
      Nelumba::Activity.discover!("alternative_url").must_equal "new_activity"
    end
  end

  describe "create_from_notification!" do
    before do
      activity_author = Nelumba::Person.create :url => "acct:wilkie@rstat.us",
                                             :uid => "AUTHOR ID"

      activity = Nelumba::Activity.new :verb  => :follow,
                                     :uid   => "1",
                                     :title => "New Title",
                                     :url   => "foo",
                                     :actor => activity_author

      @notification = mock('Nelumba::Notification')
      @notification.stubs(:activity).returns(activity)
      @notification.stubs(:account).returns("acct:wilkie@rstat.us")
      @notification.stubs(:verified?).returns(true)

      Nelumba::Person.stubs(:find_or_create_by_uid!).returns(activity_author)
      Nelumba::Person.stubs(:find_by_id).returns(activity_author)

      @identity = Nelumba::Identity.new
      @identity.stubs(:return_or_discover_public_key).returns("RSA_PUBLIC_KEY")
      @identity.stubs(:discover_person!)
      @identity.stubs(:author).returns(activity_author)

      Nelumba::Identity.stubs(:discover!).with("acct:wilkie@rstat.us").returns(@identity)
    end

    it "should verify the content" do
      @notification.expects(:verified?).with("RSA_PUBLIC_KEY").returns(true)

      Nelumba::Activity.create_from_notification! @notification
    end

    it "should discover the account that sent the salmon" do
      Nelumba::Identity.expects(:discover!).with(@notification.account).returns(@identity)

      Nelumba::Activity.create_from_notification! @notification
    end

    it "should return nil when the payload is not verified" do
      @notification.stubs(:verified?).returns(false)
      Nelumba::Activity.create_from_notification!(@notification).must_equal nil
    end

    it "should return the new activity" do
      Nelumba::Activity.create_from_notification!(@notification)
              .class.must_equal Nelumba::Activity
    end

    it "should return the old activity when already exists" do
      old = Nelumba::Activity.create_from_notification!(@notification)
      Nelumba::Activity.create_from_notification!(@notification).must_equal old
    end

    it "should return nil if the update exists under a different author" do
      old = Nelumba::Activity.create_from_notification!(@notification)

      activity_author = Nelumba::Person.create :url => "acct:bogus@rstat.us",
                                               :uid => "AUTHOR ID"
      activity = Nelumba::Activity.new :verb  => :follow,
                                       :uid   => "1",
                                       :title => "New Title",
                                       :url   => "foo",
                                       :actor => activity_author

      @notification.stubs(:activity).returns(activity)

      Nelumba::Activity.create_from_notification!(@notification).must_equal nil
    end
  end
end

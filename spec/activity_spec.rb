require_relative 'helper'

describe Lotus::Activity do
  describe "Schema" do
    it "should have a feed_id" do
      Lotus::Activity.keys.keys.must_include "feed_id"
    end

    it "should have a uid" do
      Lotus::Activity.keys.keys.must_include "uid"
    end

    it "should have a url" do
      Lotus::Activity.keys.keys.must_include "url"
    end

    it "should have a type" do
      Lotus::Activity.keys.keys.must_include "type"
    end

    it "should have an actor_id" do
      Lotus::Activity.keys.keys.must_include "actor_id"
    end

    it "should have an actor_type" do
      Lotus::Activity.keys.keys.must_include "actor_type"
    end

    it "should have a target_id" do
      Lotus::Activity.keys.keys.must_include "target_id"
    end

    it "should have a target_type" do
      Lotus::Activity.keys.keys.must_include "target_type"
    end

    it "should have an external_object_id" do
      Lotus::Activity.keys.keys.must_include "external_object_id"
    end

    it "should have an external_object_type" do
      Lotus::Activity.keys.keys.must_include "external_object_type"
    end

    it "should have a title" do
      Lotus::Activity.keys.keys.must_include "title"
    end

    it "should have a content" do
      Lotus::Activity.keys.keys.must_include "content"
    end

    it "should have a source" do
      Lotus::Activity.keys.keys.must_include "source"
    end

    it "should have an in_reply_to_ids" do
      Lotus::Activity.keys.keys.must_include "in_reply_to_ids"
    end

    it "should have an replies_ids" do
      Lotus::Activity.keys.keys.must_include "replies_ids"
    end

    it "should have an shares_ids" do
      Lotus::Activity.keys.keys.must_include "shares_ids"
    end

    it "should have an mentions_ids" do
      Lotus::Activity.keys.keys.must_include "mentions_ids"
    end

    it "should have an likes_ids" do
      Lotus::Activity.keys.keys.must_include "likes_ids"
    end

    it "should have a created_at" do
      Lotus::Activity.keys.keys.must_include "created_at"
    end

    it "should have a updated_at" do
      Lotus::Activity.keys.keys.must_include "updated_at"
    end
  end

  describe "create!" do
    it "should assign default uid" do
      activity = Lotus::Activity.new
      activity.run_callbacks :create

      activity.uid.must_equal "/activities/#{activity.id}"
    end

    it "should assign default url" do
      activity = Lotus::Activity.new
      activity.run_callbacks :create

      activity.url.must_equal "/activities/#{activity.id}"
    end
  end

  describe "#actor=" do
    it "should assign actor_id to the id of a given Lotus::Person" do
      activity = Lotus::Activity.new
      actor = Lotus::Person.new

      activity.actor = actor

      activity.actor_id.must_equal actor.id
    end

    it "should assign actor_id to the id of a given Lotus::Activity" do
      activity = Lotus::Activity.new
      actor = Lotus::Activity.new

      activity.actor = actor

      activity.actor_id.must_equal actor.id
    end

    it "should assign actor_type appropriately for a given Lotus::Person" do
      activity = Lotus::Activity.new
      actor = Lotus::Person.new

      activity.actor = actor

      activity.actor_type.must_equal "Person"
    end

    it "should assign actor_type appropriately for a given Lotus::Activity" do
      activity = Lotus::Activity.new
      actor = Lotus::Activity.new

      activity.actor = actor

      activity.actor_type.must_equal "Activity"
    end
  end

  describe "#actor" do
    it "should retrieve a stored Lotus::Person" do
      actor = Lotus::Person.create
      activity = Lotus::Activity.new(:actor_id => actor.id,
                              :actor_type => "Person")

      activity.actor.id.must_equal actor.id
      activity.actor.class.must_equal Lotus::Person
    end

    it "should retrieve a stored Lotus::Activity" do
      actor = Lotus::Activity.create
      activity = Lotus::Activity.new(:actor_id => actor.id,
                              :actor_type => "Activity")

      activity.actor.id.must_equal actor.id
      activity.actor.class.must_equal Lotus::Activity
    end
  end

  describe "find_or_create_by_uid!" do
    it "should return the existing Lotus::Activity" do
      activity = Lotus::Activity.create!(:uid => "UID",
                                         :url => "URL")

      Lotus::Activity.find_or_create_by_uid!(:uid => "UID").uid.must_equal activity.uid
    end

    it "should return the existing Lotus::Activity via Lotus::Activity" do
      activity = Lotus::Activity.create!(:uid => "UID",
                                         :url => "URL")

      lotus_activity = Lotus::Activity.new(:uid => "UID")

      Lotus::Activity.find_or_create_by_uid!(lotus_activity).uid.must_equal activity.uid
    end

    it "should create when the Lotus::Activity is not found" do
      Lotus::Activity.expects(:create!).with({:uid => "UID"})
      Lotus::Activity.find_or_create_by_uid!(:uid => "UID")
    end

    it "should create via Lotus::Activity when the Lotus::Activity is not found" do
      lotus_activity = Lotus::Activity.new
      lotus_activity.stubs(:id).returns("UID")

      Lotus::Activity.expects(:create!).with(lotus_activity)
      Lotus::Activity.find_or_create_by_uid!(lotus_activity)
    end

    it "should account for race condition where entry was created after find" do
      Lotus::Activity.stubs(:first).returns(nil).then.returns("activity")
      Lotus::Activity.stubs(:create!).raises("")
      Lotus::Activity.find_or_create_by_uid!(:uid => "UID").must_equal "activity"
    end
  end

  describe "discover!" do
    it "should call out to Lotus to discover the given Lotus::Activity" do
      Lotus.expects(:discover_activity).with("activity_url")
      Lotus::Activity.discover!("activity_url")
    end

    it "should return false when the Lotus::Activity cannot be discovered" do
      Lotus.stubs(:discover_activity).returns(false)
      Lotus::Activity.discover!("activity_url").must_equal false
    end

    it "should return the existing Lotus::Activity if it is found by url" do
      activity = Lotus::Activity.create!(:url => "activity_url",
                                  :uid => "uid")
      Lotus::Activity.discover!("activity_url").id.must_equal activity.id
    end

    it "should return the existing Lotus::Activity if uid matches" do
      activity = Lotus::Activity.create!(:url => "activity_url",
                                         :uid => "ID")

      lotus_activity = Lotus::Activity.new(:uid => "ID")

      Lotus.stubs(:discover_activity).returns(lotus_activity)
      Lotus::Activity.discover!("alternative_url").uid.must_equal activity.uid
    end

    it "should create a new Lotus::Activity from the discovered Lotus::Activity" do
      lotus_activity = Lotus::Activity.new
      lotus_activity.stubs(:id).returns("ID")

      Lotus.stubs(:discover_activity).returns(lotus_activity)
      Lotus::Activity.expects(:create!).returns("new_activity")
      Lotus::Activity.discover!("alternative_url")
    end

    it "should return the new Lotus::Activity from the discovered Lotus::Activity" do
      lotus_activity = Lotus::Activity.new
      lotus_activity.stubs(:id).returns("ID")

      Lotus.stubs(:discover_activity).returns(lotus_activity)
      Lotus::Activity.stubs(:create!).returns("new_activity")
      Lotus::Activity.discover!("alternative_url").must_equal "new_activity"
    end
  end

  describe "#parts_of_speech" do
    it "should yield the verb" do
      activity = Lotus::Activity.create(:verb => :follow)

      activity.parts_of_speech[:verb].must_equal :follow
    end

    it "should yield a default verb of :post" do
      activity = Lotus::Activity.create

      activity.parts_of_speech[:verb].must_equal :post
    end

    it "should yield the type as object_type" do
      activity = Lotus::Activity.create(:type => :person)

      activity.parts_of_speech[:object_type].must_equal :person
    end

    it "should yield a default type as :note" do
      activity = Lotus::Activity.create

      activity.parts_of_speech[:object_type].must_equal :note
    end

    it "should yield the object when it is an Lotus::Person" do
      author = Lotus::Person.create(:nickname => "wilkie")
      activity = Lotus::Activity.create(:object => author)

      activity.parts_of_speech[:object].nickname.must_equal "wilkie"
    end

    it "should yield the object when it is an Lotus::Activity" do
      object_activity = Lotus::Activity.create(:verb => :follow)
      activity = Lotus::Activity.create(:object => object_activity)

      activity.parts_of_speech[:object].verb.must_equal :follow
    end

    it "should yield the object as self when object isn't embedded" do
      activity = Lotus::Activity.create

      activity.parts_of_speech[:object].must_equal activity
    end

    it "should yield the object owner as actor of embedded Lotus::Activity" do
      author = Lotus::Person.create(:nickname => "wilkie")
      object_activity = Lotus::Activity.create(:verb  => :follow,
                                        :actor => author)
      activity = Lotus::Activity.create(:object => object_activity)

      activity.parts_of_speech[:object_owner].nickname.must_equal "wilkie"
    end

    it "should yield the object owner as the embedded Lotus::Person" do
      author = Lotus::Person.create(:nickname => "wilkie")
      activity = Lotus::Activity.create(:object => author)

      activity.parts_of_speech[:object_owner].nickname.must_equal "wilkie"
    end

    it "should yield the object owner as actor when object isn't embedded" do
      author = Lotus::Person.create(:nickname => "wilkie")
      activity = Lotus::Activity.create(:actor => author)

      activity.parts_of_speech[:object_owner].nickname.must_equal "wilkie"
    end

    it "should yield a nil value for object owner if no other possiblity" do
      activity = Lotus::Activity.create

      activity.parts_of_speech[:object_owner].must_equal nil
    end

    it "should yield the subject as the actor" do
      author = Lotus::Person.create(:nickname => "wilkie")
      activity = Lotus::Activity.create(:actor => author)

      activity.parts_of_speech[:subject].nickname.must_equal "wilkie"
    end

    it "should yield when as the modified date" do
      activity = Lotus::Activity.create

      activity.parts_of_speech[:when].must_equal activity.updated_at
    end
  end

  describe "create_from_notification!" do
    before do
      activity_author = Lotus::Person.create :url => "acct:wilkie@rstat.us",
                                             :uid => "AUTHOR ID"

      activity = Lotus::Activity.new :verb  => :follow,
                                     :uid   => "1",
                                     :title => "New Title",
                                     :url   => "foo",
                                     :actor => activity_author

      @notification = mock('Lotus::Notification')
      @notification.stubs(:activity).returns(activity)
      @notification.stubs(:account).returns("acct:wilkie@rstat.us")
      @notification.stubs(:verified?).returns(true)

      Lotus::Person.stubs(:find_or_create_by_uid!).returns(activity_author)
      Lotus::Person.stubs(:find_by_id).returns(activity_author)

      @identity = Lotus::Identity.new
      @identity.stubs(:return_or_discover_public_key).returns("RSA_PUBLIC_KEY")
      @identity.stubs(:discover_person!)
      @identity.stubs(:author).returns(activity_author)

      Lotus::Identity.stubs(:discover!).with("acct:wilkie@rstat.us").returns(@identity)
    end

    it "should verify the content" do
      @notification.expects(:verified?).with("RSA_PUBLIC_KEY").returns(true)

      Lotus::Activity.create_from_notification! @notification
    end

    it "should discover the account that sent the salmon" do
      Lotus::Identity.expects(:discover!).with(@notification.account).returns(@identity)

      Lotus::Activity.create_from_notification! @notification
    end

    it "should return nil when the payload is not verified" do
      @notification.stubs(:verified?).returns(false)
      Lotus::Activity.create_from_notification!(@notification).must_equal nil
    end

    it "should return the new activity" do
      Lotus::Activity.create_from_notification!(@notification)
              .class.must_equal Lotus::Activity
    end

    it "should return the old activity when already exists" do
      old = Lotus::Activity.create_from_notification!(@notification)
      Lotus::Activity.create_from_notification!(@notification).must_equal old
    end

    it "should return nil if the update exists under a different author" do
      old = Lotus::Activity.create_from_notification!(@notification)

      activity_author = Lotus::Person.create :url => "acct:bogus@rstat.us",
                                          :uid => "AUTHOR ID"
      activity = Lotus::Activity.new :verb  => :follow,
                                     :uid   => "1",
                                     :title => "New Title",
                                     :url   => "foo",
                                     :actor => activity_author

      @notification.stubs(:activity).returns(activity)

      Lotus::Activity.create_from_notification!(@notification).must_equal nil
    end
  end
end

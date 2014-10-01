require_relative 'helper'

describe Nelumba::Feed do
  describe "Schema" do
    it "should have a url" do
      Nelumba::Feed.keys.keys.must_include "url"
    end

    it "should have a uid" do
      Nelumba::Feed.keys.keys.must_include "uid"
    end

    it "should have categories" do
      Nelumba::Feed.keys.keys.must_include "categories"
    end

    it "should default categories to []" do
      Nelumba::Feed.new.categories.must_equal []
    end

    it "should have a rights field" do
      Nelumba::Feed.keys.keys.must_include "rights"
    end

    it "should have a title" do
      Nelumba::Feed.keys.keys.must_include "title"
    end

    it "should have a title_type" do
      Nelumba::Feed.keys.keys.must_include "title_type"
    end

    it "should have a subtitle" do
      Nelumba::Feed.keys.keys.must_include "subtitle"
    end

    it "should have a subtitle_type" do
      Nelumba::Feed.keys.keys.must_include "subtitle_type"
    end

    it "should have contributors_ids" do
      Nelumba::Feed.keys.keys.must_include "contributors_ids"
    end

    it "should have authors_ids" do
      Nelumba::Feed.keys.keys.must_include "authors_ids"
    end

    it "should have items_ids" do
      Nelumba::Feed.keys.keys.must_include "items_ids"
    end

    it "should have a generator" do
      Nelumba::Feed.keys.keys.must_include "generator"
    end

    it "should have a published" do
      Nelumba::Feed.keys.keys.must_include "published"
    end

    it "should have a updated" do
      Nelumba::Feed.keys.keys.must_include "updated"
    end

    it "should have a person_id" do
      Nelumba::Feed.keys.keys.must_include "person_id"
    end

    it "should have a following_ids array" do
      Nelumba::Feed.keys.keys.must_include "following_ids"
    end

    it "should have many following" do
      Nelumba::Feed.has_many?(:following).must_equal true
    end

    it "should have a followers_ids array" do
      Nelumba::Feed.keys.keys.must_include "followers_ids"
    end

    it "should have many followers" do
      Nelumba::Feed.has_many?(:followers).must_equal true
    end

    it "should have a subscription_secret" do
      Nelumba::Feed.keys.keys.must_include "subscription_secret"
    end

    it "should have a verification_token" do
      Nelumba::Feed.keys.keys.must_include "verification_token"
    end

    it "should belong to person" do
      Nelumba::Feed.belongs_to?(:person).must_equal true
    end
  end

  describe "find_or_create_by_uid!" do
    it "should return the existing Nelumba::Feed" do
      feed = Nelumba::Feed.create!(:uid => "UID")

      Nelumba::Feed.find_or_create_by_uid!(:uid => "UID").id.must_equal feed.id
    end

    it "should return the existing Nelumba::Feed via Nelumba::Feed" do
      feed = Nelumba::Feed.create!(:uid => "UID")

      nelumba_feed = Nelumba::Feed.new
      nelumba_feed.stubs(:uid).returns("UID")

      Nelumba::Feed.find_or_create_by_uid!(nelumba_feed).uid.must_equal feed.uid
    end

    it "should create when the Nelumba::Feed is not found" do
      Nelumba::Feed.expects(:create!).with({:uid => "UID"})
      Nelumba::Feed.find_or_create_by_uid!(:uid => "UID")
    end

    it "should create via Nelumba::Feed when the Nelumba::Feed is not found" do
      nelumba_feed = Nelumba::Feed.new
      nelumba_feed.stubs(:id).returns("UID")

      Nelumba::Feed.expects(:create!).with(nelumba_feed)
      Nelumba::Feed.find_or_create_by_uid!(nelumba_feed)
    end

    it "should account for race condition where entry was created after find" do
      Nelumba::Feed.stubs(:first).returns(nil).then.returns("feed")
      Nelumba::Feed.stubs(:create!).raises("")
      Nelumba::Feed.find_or_create_by_uid!(:uid => "UID").must_equal "feed"
    end
  end

  describe "#initialize" do
    it "should allow a Nelumba::Feed" do
      nelumba_feed = Nelumba::Feed.new(:uid => "UID",
                                   :authors => [],
                                   :contributors => [],
                                   :items => [])

      Nelumba::Feed.new(nelumba_feed).uid.must_equal "UID"
    end

    it "should find or create Nelumba::Persons for those given in Nelumba::Feed" do
      author = Nelumba::Person.new
      Nelumba::Person.expects(:find_or_create_by_uid!).returns(author)

      Nelumba::Feed.new(:id => "UID",
                      :authors => [{:uid => "author UID",
                                    :url => "author URL"}],
                      :contributors => [],
                      :items => [])
    end

    it "should find or create Nelumba::Persons for contributors given in Nelumba::Feed" do
      author = Nelumba::Person.new
      Nelumba::Person.expects(:find_or_create_by_uid!).returns(author)

      Nelumba::Feed.new(:id => "UID",
                      :contributors => [{:uid => "author UID",
                                         :url => "author URL"}],
                      :authors => [],
                      :items => [])
    end

    it "should find or create Nelumba::Activities for items given in Nelumba::Feed" do
      activity = Nelumba::Activity.new
      Nelumba::Activity.expects(:find_or_create_by_uid!).returns(activity)

      Nelumba::Feed.new(:id => "UID",
                      :items => [{:uid => "author UID",
                                  :url => "author URL"}],
                      :authors => [],
                      :contributors => [])
    end
  end

  describe "discover!" do
    it "should use Nelumba to discover the feed given by the url" do
      Nelumba::Discover.expects(:feed).with("feed_url")
      Nelumba::Feed.discover!("feed_url")
    end

    it "should return false when the feed cannot be discovered" do
      Nelumba::Discover.stubs(:feed).returns(nil)
      Nelumba::Feed.discover!("feed_url").must_equal false
    end

    it "should create a new feed when the discovered feed does not exist" do
      nelumba_feed = Nelumba::Feed.new
      nelumba_feed.stubs(:id).returns("UID")
      Nelumba::Discover.stubs(:feed).returns(nelumba_feed)

      Nelumba::Feed.expects(:create!).with(nelumba_feed)
      Nelumba::Feed.discover!("feed_url")
    end

    it "should return a known feed when url matches given" do
      feed = Nelumba::Feed.new
      Nelumba::Feed.stubs(:first).with(has_entry(:url, "feed_url")).returns(feed)

      Nelumba::Feed.discover!("feed_url").must_equal feed
    end

    it "should return a known feed when uids match" do
      nelumba_feed = Nelumba::Feed.new
      nelumba_feed.stubs(:uid).returns("UID")
      Nelumba::Discover.stubs(:feed).returns(nelumba_feed)

      feed = Nelumba::Feed.new
      Nelumba::Feed.stubs(:first).with(has_entry(:url, "feed_url")).returns(nil)
      Nelumba::Feed.stubs(:first).with(has_entry(:uid, "UID")).returns(feed)
      Nelumba::Discover.stubs(:feed).returns(nelumba_feed)

      Nelumba::Feed.discover!("feed_url").must_equal feed
    end
  end

  describe "#post!" do
    it "should allow a Hash to be given" do
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      activity = Nelumba::Activity.new
      activity.stubs(:save)

      hash = {}
      Nelumba::Activity.expects(:create!).with(hash).returns(activity)

      feed.post! hash
    end

    it "should allow a Nelumba::Activity to be given" do
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      activity = Nelumba::Activity.new
      activity.stubs(:save)

      nelumba_activity = Nelumba::Activity.new
      Nelumba::Activity.expects(:create!).never
      nelumba_activity.expects(:save).at_least 1

      feed.post! nelumba_activity
    end

    it "should save the association to this feed" do
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      activity = Nelumba::Activity.new
      activity.expects(:feed_id=).with(feed.id)
      activity.expects(:save).at_least 1

      feed.post! activity
    end

    it "should add the activity to the items" do
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      activity = Nelumba::Activity.new
      activity.stubs(:save)

      feed.post! activity

      feed.items_ids.must_include activity.id
    end

    it "should save" do
      feed = Nelumba::Feed.new

      activity = Nelumba::Activity.new
      activity.stubs(:save)

      feed.expects(:save)

      feed.post! activity
    end
  end

  describe "#repost!" do
    it "should simply add the activity to items" do
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      activity = Nelumba::Activity.new
      activity.stubs(:save)

      feed.repost! activity

      feed.items_ids.must_include activity.id
    end

    it "should save" do
      feed = Nelumba::Feed.new

      activity = Nelumba::Activity.new
      activity.stubs(:save)

      feed.expects(:save)

      feed.repost! activity
    end
  end

  describe "#delete!" do
    it "should remove the given activity from items" do
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      activity = Nelumba::Activity.new
      activity.stubs(:save)

      feed.items << activity

      feed.delete! activity
      feed.items_ids.wont_include activity.id
    end

    it "should save" do
      feed = Nelumba::Feed.new

      activity = Nelumba::Activity.new
      activity.stubs(:save)

      feed.items << activity

      feed.expects(:save)
      feed.delete! activity
    end
  end

  describe "#merge!" do
    it "should update base attributes" do
      feed = Nelumba::Feed.new
      feed.stubs(:save)
      feed.stubs(:save!)

      nelumba_feed = Nelumba::Feed.new
      nelumba_feed.stubs(:authors).returns([])
      nelumba_feed.stubs(:contributors).returns([])
      nelumba_feed.stubs(:items).returns([])
      nelumba_feed.stubs(:to_hash).returns({:rights => "NEW RIGHTS",
                                          :url => "NEW URL",
                                          :subtitle => "NEW SUBTITLE"})

      feed.merge! nelumba_feed

      feed.subtitle.must_equal "NEW SUBTITLE"
    end
  end

  describe "#ordered" do
    it "should return a query for the items in descending order" do
      feed = Nelumba::Feed.new
      feed.stubs(:save)
      feed.items_ids = ["id1", "id2"]

      query = stub('Plucky')
      query.expects(:order)
        .with(has_entry(:published, :desc))
        .returns("ordered")

      Nelumba::Activity
        .expects(:where)
        .with(has_entry(:id, ["id1", "id2"]))
        .returns(query)

      feed.ordered.must_equal "ordered"
    end
  end

  describe "#follow!" do
    it "should add the given feed to the following list" do
      aggregate = Nelumba::Feed.new
      aggregate.stubs(:save)

      feed = Nelumba::Feed.new
      feed.stubs(:save)

      aggregate.follow! feed

      aggregate.following_ids.must_include feed.id
    end

    it "should save" do
      aggregate = Nelumba::Feed.new
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      aggregate.expects(:save)

      aggregate.follow! feed
    end
  end

  describe "#unfollow!" do
    it "should remove the given feed from the following list" do
      aggregate = Nelumba::Feed.new
      aggregate.stubs(:save)

      feed = Nelumba::Feed.new
      feed.stubs(:save)

      aggregate.unfollow! feed

      aggregate.following_ids.wont_include feed.id
    end

    it "should save" do
      aggregate = Nelumba::Feed.new
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      aggregate.expects(:save)

      aggregate.unfollow! feed
    end
  end

  describe "#followed_by!" do
    it "should add the given feed to the followers list" do
      aggregate = Nelumba::Feed.new
      aggregate.stubs(:save)

      feed = Nelumba::Feed.new
      feed.stubs(:save)

      aggregate.followed_by! feed

      aggregate.followers_ids.must_include feed.id
    end

    it "should save" do
      aggregate = Nelumba::Feed.new
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      aggregate.expects(:save)

      aggregate.followed_by! feed
    end
  end

  describe "#unfollowed_by!" do
    it "should remove the given feed from the followers list" do
      aggregate = Nelumba::Feed.new
      aggregate.stubs(:save)

      feed = Nelumba::Feed.new
      feed.stubs(:save)

      aggregate.unfollowed_by! feed

      aggregate.followers_ids.wont_include feed.id
    end

    it "should save" do
      aggregate = Nelumba::Feed.new
      feed = Nelumba::Feed.new
      feed.stubs(:save)

      aggregate.expects(:save)

      aggregate.unfollowed_by! feed
    end
  end

  describe "#publish" do
    it "should repost in every feed that follows this aggregate" do
      activity = Nelumba::Activity.new

      aggregate = Nelumba::Feed.new
      feeds = [Nelumba::Feed.new, Nelumba::Feed.new, Nelumba::Feed.new]

      feeds.each do |f|
        f.expects(:repost!).with(activity)
      end

      aggregate.stubs(:followers).returns(feeds)
      aggregate.publish activity
    end
  end
end

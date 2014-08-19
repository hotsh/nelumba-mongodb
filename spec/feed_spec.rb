require_relative 'helper'

describe Lotus::Feed do
  describe "Schema" do
    it "should have a url" do
      Lotus::Feed.keys.keys.must_include "url"
    end

    it "should have a uid" do
      Lotus::Feed.keys.keys.must_include "uid"
    end

    it "should have categories" do
      Lotus::Feed.keys.keys.must_include "categories"
    end

    it "should default categories to []" do
      Lotus::Feed.new.categories.must_equal []
    end

    it "should have a rights field" do
      Lotus::Feed.keys.keys.must_include "rights"
    end

    it "should have a title" do
      Lotus::Feed.keys.keys.must_include "title"
    end

    it "should have a title_type" do
      Lotus::Feed.keys.keys.must_include "title_type"
    end

    it "should have a subtitle" do
      Lotus::Feed.keys.keys.must_include "subtitle"
    end

    it "should have a subtitle_type" do
      Lotus::Feed.keys.keys.must_include "subtitle_type"
    end

    it "should have contributors_ids" do
      Lotus::Feed.keys.keys.must_include "contributors_ids"
    end

    it "should have authors_ids" do
      Lotus::Feed.keys.keys.must_include "authors_ids"
    end

    it "should have items_ids" do
      Lotus::Feed.keys.keys.must_include "items_ids"
    end

    it "should have a generator" do
      Lotus::Feed.keys.keys.must_include "generator"
    end

    it "should have a published" do
      Lotus::Feed.keys.keys.must_include "published"
    end

    it "should have a updated" do
      Lotus::Feed.keys.keys.must_include "updated"
    end

    it "should have a person_id" do
      Lotus::Feed.keys.keys.must_include "person_id"
    end

    it "should have a following_ids array" do
      Lotus::Feed.keys.keys.must_include "following_ids"
    end

    it "should have many following" do
      Lotus::Feed.has_many?(:following).must_equal true
    end

    it "should have a followers_ids array" do
      Lotus::Feed.keys.keys.must_include "followers_ids"
    end

    it "should have many followers" do
      Lotus::Feed.has_many?(:followers).must_equal true
    end

    it "should have a subscription_secret" do
      Lotus::Feed.keys.keys.must_include "subscription_secret"
    end

    it "should have a verification_token" do
      Lotus::Feed.keys.keys.must_include "verification_token"
    end

    it "should belong to person" do
      Lotus::Feed.belongs_to?(:person).must_equal true
    end
  end

  describe "find_or_create_by_uid!" do
    it "should return the existing Lotus::Feed" do
      feed = Lotus::Feed.create!(:uid => "UID")

      Lotus::Feed.find_or_create_by_uid!(:uid => "UID").id.must_equal feed.id
    end

    it "should return the existing Lotus::Feed via Lotus::Feed" do
      feed = Lotus::Feed.create!(:uid => "UID")

      lotus_feed = Lotus::Feed.new
      lotus_feed.stubs(:uid).returns("UID")

      Lotus::Feed.find_or_create_by_uid!(lotus_feed).uid.must_equal feed.uid
    end

    it "should create when the Lotus::Feed is not found" do
      Lotus::Feed.expects(:create!).with({:uid => "UID"})
      Lotus::Feed.find_or_create_by_uid!(:uid => "UID")
    end

    it "should create via Lotus::Feed when the Lotus::Feed is not found" do
      lotus_feed = Lotus::Feed.new
      lotus_feed.stubs(:id).returns("UID")

      Lotus::Feed.expects(:create!).with(lotus_feed)
      Lotus::Feed.find_or_create_by_uid!(lotus_feed)
    end

    it "should account for race condition where entry was created after find" do
      Lotus::Feed.stubs(:first).returns(nil).then.returns("feed")
      Lotus::Feed.stubs(:create!).raises("")
      Lotus::Feed.find_or_create_by_uid!(:uid => "UID").must_equal "feed"
    end
  end

  describe "#initialize" do
    it "should allow a Lotus::Feed" do
      lotus_feed = Lotus::Feed.new(:uid => "UID",
                                   :authors => [],
                                   :contributors => [],
                                   :items => [])

      Lotus::Feed.new(lotus_feed).uid.must_equal "UID"
    end

    it "should find or create Lotus::Persons for those given in Lotus::Feed" do
      author = Lotus::Person.new
      Lotus::Person.expects(:find_or_create_by_uid!).returns(author)

      Lotus::Feed.new(:id => "UID",
                      :authors => [{:uid => "author UID",
                                    :url => "author URL"}],
                      :contributors => [],
                      :items => [])
    end

    it "should find or create Lotus::Persons for contributors given in Lotus::Feed" do
      author = Lotus::Person.new
      Lotus::Person.expects(:find_or_create_by_uid!).returns(author)

      Lotus::Feed.new(:id => "UID",
                      :contributors => [{:uid => "author UID",
                                         :url => "author URL"}],
                      :authors => [],
                      :items => [])
    end

    it "should find or create Lotus::Activities for items given in Lotus::Feed" do
      activity = Lotus::Activity.new
      Lotus::Activity.expects(:find_or_create_by_uid!).returns(activity)

      Lotus::Feed.new(:id => "UID",
                      :items => [{:uid => "author UID",
                                  :url => "author URL"}],
                      :authors => [],
                      :contributors => [])
    end
  end

  describe "discover!" do
    it "should use Lotus to discover the feed given by the url" do
      Lotus.expects(:discover_feed).with("feed_url")
      Lotus::Feed.discover!("feed_url")
    end

    it "should return false when the feed cannot be discovered" do
      Lotus.stubs(:discover_feed).returns(nil)
      Lotus::Feed.discover!("feed_url").must_equal false
    end

    it "should create a new feed when the discovered feed does not exist" do
      lotus_feed = Lotus::Feed.new
      lotus_feed.stubs(:id).returns("UID")
      Lotus.stubs(:discover_feed).returns(lotus_feed)

      Lotus::Feed.expects(:create!).with(lotus_feed)
      Lotus::Feed.discover!("feed_url")
    end

    it "should return a known feed when url matches given" do
      feed = Lotus::Feed.new
      Lotus::Feed.stubs(:first).with(has_entry(:url, "feed_url")).returns(feed)

      Lotus::Feed.discover!("feed_url").must_equal feed
    end

    it "should return a known feed when uids match" do
      lotus_feed = Lotus::Feed.new
      lotus_feed.stubs(:uid).returns("UID")
      Lotus.stubs(:discover_feed).returns(lotus_feed)

      feed = Lotus::Feed.new
      Lotus::Feed.stubs(:first).with(has_entry(:url, "feed_url")).returns(nil)
      Lotus::Feed.stubs(:first).with(has_entry(:uid, "UID")).returns(feed)
      Lotus.stubs(:discover_feed).returns(lotus_feed)

      Lotus::Feed.discover!("feed_url").must_equal feed
    end
  end

  describe "#post!" do
    it "should allow a Hash to be given" do
      feed = Lotus::Feed.new
      feed.stubs(:save)

      activity = Lotus::Activity.new
      activity.stubs(:save)

      hash = {}
      Lotus::Activity.expects(:create!).with(hash).returns(activity)

      feed.post! hash
    end

    it "should allow a Lotus::Activity to be given" do
      feed = Lotus::Feed.new
      feed.stubs(:save)

      activity = Lotus::Activity.new
      activity.stubs(:save)

      lotus_activity = Lotus::Activity.new
      Lotus::Activity.expects(:create!).never
      lotus_activity.expects(:save).at_least 1

      feed.post! lotus_activity
    end

    it "should save the association to this feed" do
      feed = Lotus::Feed.new
      feed.stubs(:save)

      activity = Lotus::Activity.new
      activity.expects(:feed_id=).with(feed.id)
      activity.expects(:save).at_least 1

      feed.post! activity
    end

    it "should add the activity to the items" do
      feed = Lotus::Feed.new
      feed.stubs(:save)

      activity = Lotus::Activity.new
      activity.stubs(:save)

      feed.post! activity

      feed.items_ids.must_include activity.id
    end

    it "should save" do
      feed = Lotus::Feed.new

      activity = Lotus::Activity.new
      activity.stubs(:save)

      feed.expects(:save)

      feed.post! activity
    end
  end

  describe "#repost!" do
    it "should simply add the activity to items" do
      feed = Lotus::Feed.new
      feed.stubs(:save)

      activity = Lotus::Activity.new
      activity.stubs(:save)

      feed.repost! activity

      feed.items_ids.must_include activity.id
    end

    it "should save" do
      feed = Lotus::Feed.new

      activity = Lotus::Activity.new
      activity.stubs(:save)

      feed.expects(:save)

      feed.repost! activity
    end
  end

  describe "#delete!" do
    it "should remove the given activity from items" do
      feed = Lotus::Feed.new
      feed.stubs(:save)

      activity = Lotus::Activity.new
      activity.stubs(:save)

      feed.items << activity

      feed.delete! activity
      feed.items_ids.wont_include activity.id
    end

    it "should save" do
      feed = Lotus::Feed.new

      activity = Lotus::Activity.new
      activity.stubs(:save)

      feed.items << activity

      feed.expects(:save)
      feed.delete! activity
    end
  end

  describe "#merge!" do
    it "should update base attributes" do
      feed = Lotus::Feed.new
      feed.stubs(:save)
      feed.stubs(:save!)

      lotus_feed = Lotus::Feed.new
      lotus_feed.stubs(:authors).returns([])
      lotus_feed.stubs(:contributors).returns([])
      lotus_feed.stubs(:items).returns([])
      lotus_feed.stubs(:to_hash).returns({:rights => "NEW RIGHTS",
                                          :url => "NEW URL",
                                          :subtitle => "NEW SUBTITLE"})

      feed.merge! lotus_feed

      feed.subtitle.must_equal "NEW SUBTITLE"
    end
  end

  describe "#ordered" do
    it "should return a query for the items in descending order" do
      feed = Lotus::Feed.new
      feed.stubs(:save)
      feed.items_ids = ["id1", "id2"]

      query = stub('Plucky')
      query.expects(:order)
        .with(has_entry(:published, :desc))
        .returns("ordered")

      Lotus::Activity
        .expects(:where)
        .with(has_entry(:id, ["id1", "id2"]))
        .returns(query)

      feed.ordered.must_equal "ordered"
    end
  end

  describe "#follow!" do
    it "should add the given feed to the following list" do
      aggregate = Lotus::Feed.new
      aggregate.stubs(:save)

      feed = Lotus::Feed.new
      feed.stubs(:save)

      aggregate.follow! feed

      aggregate.following_ids.must_include feed.id
    end

    it "should save" do
      aggregate = Lotus::Feed.new
      feed = Lotus::Feed.new
      feed.stubs(:save)

      aggregate.expects(:save)

      aggregate.follow! feed
    end
  end

  describe "#unfollow!" do
    it "should remove the given feed from the following list" do
      aggregate = Lotus::Feed.new
      aggregate.stubs(:save)

      feed = Lotus::Feed.new
      feed.stubs(:save)

      aggregate.unfollow! feed

      aggregate.following_ids.wont_include feed.id
    end

    it "should save" do
      aggregate = Lotus::Feed.new
      feed = Lotus::Feed.new
      feed.stubs(:save)

      aggregate.expects(:save)

      aggregate.unfollow! feed
    end
  end

  describe "#followed_by!" do
    it "should add the given feed to the followers list" do
      aggregate = Lotus::Feed.new
      aggregate.stubs(:save)

      feed = Lotus::Feed.new
      feed.stubs(:save)

      aggregate.followed_by! feed

      aggregate.followers_ids.must_include feed.id
    end

    it "should save" do
      aggregate = Lotus::Feed.new
      feed = Lotus::Feed.new
      feed.stubs(:save)

      aggregate.expects(:save)

      aggregate.followed_by! feed
    end
  end

  describe "#unfollowed_by!" do
    it "should remove the given feed from the followers list" do
      aggregate = Lotus::Feed.new
      aggregate.stubs(:save)

      feed = Lotus::Feed.new
      feed.stubs(:save)

      aggregate.unfollowed_by! feed

      aggregate.followers_ids.wont_include feed.id
    end

    it "should save" do
      aggregate = Lotus::Feed.new
      feed = Lotus::Feed.new
      feed.stubs(:save)

      aggregate.expects(:save)

      aggregate.unfollowed_by! feed
    end
  end

  describe "#publish" do
    it "should repost in every feed that follows this aggregate" do
      activity = Lotus::Activity.new

      aggregate = Lotus::Feed.new
      feeds = [Lotus::Feed.new, Lotus::Feed.new, Lotus::Feed.new]

      feeds.each do |f|
        f.expects(:repost!).with(activity)
      end

      aggregate.stubs(:followers).returns(feeds)
      aggregate.publish activity
    end
  end
end

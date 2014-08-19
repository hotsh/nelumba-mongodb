require_relative 'helper'

describe Lotus::Person do
  describe "Schema" do
    it "should have one authorization" do
      Lotus::Person.has_one?(:authorization).must_equal true
    end

    it "should have one identity" do
      Lotus::Person.has_one?(:identity).must_equal true
    end

    it "should have one avatar" do
      Lotus::Person.has_one?(:avatar).must_equal true
    end

    it "should have a uid" do
      Lotus::Person.keys.keys.must_include "uid"
    end

    it "should have a nickname" do
      Lotus::Person.keys.keys.must_include "nickname"
    end

    it "should have an extended_name" do
      Lotus::Person.keys.keys.must_include "extended_name"
    end

    it "should have a url" do
      Lotus::Person.keys.keys.must_include "url"
    end

    it "should have an email" do
      Lotus::Person.keys.keys.must_include "email"
    end

    it "should have a name" do
      Lotus::Person.keys.keys.must_include "name"
    end

    it "should have an organization" do
      Lotus::Person.keys.keys.must_include "organization"
    end

    it "should have an address" do
      Lotus::Person.keys.keys.must_include "address"
    end

    it "should have a gender" do
      Lotus::Person.keys.keys.must_include "gender"
    end

    it "should have a note" do
      Lotus::Person.keys.keys.must_include "note"
    end

    it "should have a display_name" do
      Lotus::Person.keys.keys.must_include "display_name"
    end

    it "should have a preferred_username" do
      Lotus::Person.keys.keys.must_include "preferred_username"
    end

    it "should have a birthday" do
      Lotus::Person.keys.keys.must_include "birthday"
    end

    it "should have an anniversary" do
      Lotus::Person.keys.keys.must_include "anniversary"
    end

    it "should have a published" do
      Lotus::Person.keys.keys.must_include "published"
    end

    it "should have a updated" do
      Lotus::Person.keys.keys.must_include "updated"
    end

    it "should have an activities id" do
      Lotus::Person.keys.keys.must_include "activities_id"
    end

    it "should have a timeline id" do
      Lotus::Person.keys.keys.must_include "timeline_id"
    end

    it "should have a favorites id" do
      Lotus::Person.keys.keys.must_include "favorites_id"
    end

    it "should have a shared id" do
      Lotus::Person.keys.keys.must_include "shared_id"
    end

    it "should have a replies id" do
      Lotus::Person.keys.keys.must_include "replies_id"
    end

    it "should have a mentions id" do
      Lotus::Person.keys.keys.must_include "mentions_id"
    end

    it "should have a following_ids array" do
      Lotus::Person.keys.keys.must_include "following_ids"
    end

    it "should have a followers_ids array" do
      Lotus::Person.keys.keys.must_include "followers_ids"
    end
  end

  describe "create" do
    before do
      @author = Lotus::Person.new
      Lotus::Person.stubs(:create).returns(@author)

      @aggregate = Lotus::Feed.new
      Lotus::Feed.stubs(:create).returns(@aggregate)

      @person = Lotus::Person.new
    end
  end

  describe "new_local" do
    before do
      @aggregate = Lotus::Feed.new
      Lotus::Feed.stubs(:new).returns(@aggregate)

      @person = Lotus::Person.new
      Lotus::Person.stubs(:new).returns(@person)
    end

    it "should create an activities aggregate upon creation" do
      @person.expects(:activities_id=).with(@aggregate.id)
      Lotus::Person.new_local "wilkie", "www.example.com", true
    end

    it "should create a timeline aggregate upon creation" do
      @person.expects(:timeline_id=).with(@aggregate.id)
      Lotus::Person.new_local "wilkie", "www.example.com", true
    end

    it "should create a shared aggregate upon creation" do
      @person.expects(:shared_id=).with(@aggregate.id)
      Lotus::Person.new_local "wilkie", "www.example.com", true
    end

    it "should create a favorites aggregate upon creation" do
      @person.expects(:favorites_id=).with(@aggregate.id)
      Lotus::Person.new_local "wilkie", "www.example.com", true
    end

    it "should create a replies aggregate upon creation" do
      @person.expects(:replies_id=).with(@aggregate.id)
      Lotus::Person.new_local "wilkie", "www.example.com", true
    end

    it "should create a mentions aggregate upon creation" do
      @person.expects(:mentions_id=).with(@aggregate.id)
      Lotus::Person.new_local "wilkie", "www.example.com", true
    end

    it "should set the url to a valid url for the given domain" do
      @person.expects(:url=).with("http://status.example.com/people/#{@person.id}")
      Lotus::Person.new_local "wilkie", "status.example.com", false
    end

    it "should respect ssl requirements in the url" do
      @person.expects(:url=).with("https://status.example.com/people/#{@person.id}")
      Lotus::Person.new_local "wilkie", "status.example.com", true
    end
  end

  describe "#follow!" do
    before do
      @person = Lotus::Person.new
      @person.stubs(:save)

      timeline = Lotus::Feed.new
      timeline.stubs(:follow!)
      timeline.stubs(:save)
      @person.stubs(:timeline).returns(timeline)

      activities = Lotus::Feed.new
      activities.stubs(:save)
      activities.stubs(:post!)
      @person.stubs(:activities).returns(activities)

      @author = Lotus::Person.new({:local => false})
      @author.stubs(:local?).returns(false)

      feed = Lotus::Feed.new
      feed.stubs(:save)

      outbox = Lotus::Feed.new
      outbox.stubs(:save)
      outbox.stubs(:feed).returns(feed)

      identity = Lotus::Identity.new(:outbox_id => outbox.id,
                              :author_id => @author.id)
      identity.stubs(:outbox).returns(outbox)
      identity.stubs(:person).returns(@author)
      identity.stubs(:save)

      @author.stubs(:identity).returns(identity)
      @author.stubs(:save)

      @person.stubs(:author).returns(@author)
    end

    it "should add the given remote Lotus::Person to the following list" do
      @person.follow! @author
      @person.following_ids.must_include @author.id
    end

    it "should allow an Lotus::Identity to be given" do
      @person.follow! @author.identity
      @person.following_ids.must_include @author.id
    end

    it "should add the given local Lotus::Person to the following list" do
      @author.stubs(:local?).returns(true)

      @author.stubs(:followed_by!)

      @person.follow! @author
      @person.following_ids.must_include @author.id
    end

    it "should add self to the local Lotus::Person's followers list" do
      @author.stubs(:local?).returns(true)

      @author.expects(:followed_by!)

      @person.follow! @author
    end
  end

  describe "#unfollow!" do
    before do
      @person = Lotus::Person.new
      @person.stubs(:save)

      timeline = Lotus::Feed.new
      timeline.stubs(:follow!)
      timeline.stubs(:save)
      @person.stubs(:timeline).returns(timeline)

      activities = Lotus::Feed.new
      activities.stubs(:save)
      activities.stubs(:post!)
      @person.stubs(:activities).returns(activities)

      @author = Lotus::Person.new

      feed = Lotus::Feed.new
      feed.stubs(:save)

      outbox = Lotus::Feed.new
      outbox.stubs(:save)
      outbox.stubs(:feed).returns(feed)

      identity = Lotus::Identity.new(:outbox_id => outbox.id,
                              :author_id => @author.id)
      identity.stubs(:outbox).returns(outbox)
      identity.stubs(:person).returns(@author)
      identity.stubs(:save)

      @author.stubs(:identity).returns(identity)
      @author.stubs(:save)

      @person.following_ids = [@author.id]
    end

    it "should remove the given remote Lotus::Person from the following list" do
      @person.unfollow! @author
      @person.following_ids.wont_include @author.id
    end

    it "should allow an Lotus::Identity to be given" do
      @person.unfollow! @author.identity
      @person.following_ids.wont_include @author.id
    end

    it "should remove the given local Lotus::Person from the following list" do
      @author.stubs(:local).returns(true)

      local_person = Lotus::Person.new
      local_person.stubs(:save)
      @author.stubs(:person).returns(local_person)

      local_person.stubs(:unfollowed_by!)

      @person.unfollow! @author
      @person.following_ids.wont_include @author.id
    end

    it "should remove self from the local Lotus::Person's followers list" do
      @author.stubs(:local?).returns(true)

      @author.expects(:unfollowed_by!)

      @person.unfollow! @author
    end
  end

  describe "#followed_by!" do
    before do
      activities = Lotus::Feed.new
      activities.stubs(:followed_by!)

      @person = Lotus::Person.new
      @person.stubs(:save)
      @person.stubs(:activities).returns(activities)

      @author = Lotus::Person.new
      @author.stubs(:save)

      aggregate = Lotus::Feed.new
      aggregate.stubs(:feed).returns(Lotus::Feed.new)
      aggregate.stubs(:save)

      aggregate_in = Lotus::Feed.new
      aggregate_in.stubs(:feed).returns(Lotus::Feed.new)
      aggregate_in.stubs(:save)

      @identity = Lotus::Identity.new(:outbox_id => aggregate.id,
                               :inbox_id  => aggregate_in.id,
                               :author_id => @author.id)

      @identity.stubs(:person).returns(@author)
      @identity.stubs(:outbox).returns(aggregate)
      @identity.stubs(:inbox).returns(aggregate_in)
      @author.stubs(:identity).returns(@identity)
    end

    it "should add the given remote Lotus::Person to our followers list" do
      @person.followed_by! @author
      @person.followers_ids.must_include @author.id
    end

    it "should add the given Lotus::Identity to our followers list" do
      @person.followed_by! @identity
      @person.followers_ids.must_include @author.id
    end

    it "should add outbox to activities' followers list" do
      @person.activities.expects(:followed_by!).with(@identity.inbox)
      @person.followed_by! @author
    end
  end

  describe "#unfollowed_by!" do
    before do
      activities = Lotus::Feed.new
      activities.stubs(:unfollowed_by!)

      @person = Lotus::Person.new
      @person.stubs(:save)
      @person.stubs(:activities).returns(activities)

      @author = Lotus::Person.new
      @author.stubs(:save)

      aggregate = Lotus::Feed.new
      aggregate.stubs(:save)

      aggregate_in = Lotus::Feed.new
      aggregate_in.stubs(:save)

      @identity = Lotus::Identity.new(:outbox_id => aggregate.id,
                               :inbox_id  => aggregate_in.id,
                               :author_id => @author.id)

      @identity.stubs(:person).returns(@author)
      @identity.stubs(:outbox).returns(aggregate)
      @identity.stubs(:inbox).returns(aggregate_in)
      @author.stubs(:identity).returns(@identity)
    end

    it "should remove the given remote Lotus::Person from our followers list" do
      @person.unfollowed_by! @author
      @person.followers_ids.wont_include @author.id
    end

    it "should remove the given Lotus::Identity from our followers list" do
      @person.unfollowed_by! @identity
      @person.followers_ids.wont_include @author.id
    end

    it "should remove outbox from activities' followers list" do
      @person.activities.expects(:unfollowed_by!).with(@identity.inbox)
      @person.unfollowed_by! @author
    end
  end

  describe "#favorite!" do
    before do
      activities = Lotus::Feed.new
      activities.stubs(:post!)
      favorites = Lotus::Feed.new
      favorites.stubs(:repost!)

      @person = Lotus::Person.new
      @person.stubs(:activities).returns(activities)
      @person.stubs(:favorites).returns(favorites)
    end

    it "should repost the given activity to our favorites aggregate" do
      activity = Lotus::Activity.new

      @person.favorites.expects(:repost!).with(activity)
      @person.favorite! activity
    end

    it "should post an activity to our activities with favorite verb" do
      activity = Lotus::Activity.new

      @person.activities.expects(:post!).with(has_entry(:verb, :favorite))
      @person.favorite! activity
    end

    it "should post an activity to our activities with our author as actor" do
      activity = Lotus::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:actor_id   => @person.id,
                          :actor_type => 'Person'))

      @person.favorite! activity
    end

    it "should post an activity to our activities with favorited activity" do
      activity = Lotus::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:external_object_id   => activity.id,
                          :external_object_type => 'Activity'))

      @person.favorite! activity
    end
  end

  describe "#unfavorite!" do
    before do
      activities = Lotus::Feed.new
      activities.stubs(:post!)
      favorites = Lotus::Feed.new
      favorites.stubs(:delete!)

      author = Lotus::Person.new

      @person = Lotus::Person.new
      @person.stubs(:activities).returns(activities)
      @person.stubs(:favorites).returns(favorites)
      @person.stubs(:author).returns(author)
    end

    it "should repost the given activity to our favorites aggregate" do
      activity = Lotus::Activity.new

      @person.favorites.expects(:delete!).with(activity)
      @person.unfavorite! activity
    end

    it "should post an activity to our activities with favorite verb" do
      activity = Lotus::Activity.new

      @person.activities.expects(:post!).with(has_entry(:verb, :unfavorite))
      @person.unfavorite! activity
    end

    it "should post an activity to our activities with our author as actor" do
      activity = Lotus::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:actor_id   => @person.id,
                          :actor_type => 'Person'))

      @person.unfavorite! activity
    end

    it "should post an activity to our activities with favorited activity" do
      activity = Lotus::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:external_object_id   => activity.id,
                          :external_object_type => 'Activity'))

      @person.unfavorite! activity
    end
  end

  describe "#mentioned_by!" do
    it "should repost the activity to our mentions aggregate" do
      person = Lotus::Person.new
      activity = Lotus::Activity.new

      person.stubs(:mentions).returns(Lotus::Feed.new)

      person.mentions.expects(:repost!).with(activity)
      person.mentioned_by! activity
    end
  end

  describe "#replied_by!" do
    it "should repost the activity to our replies aggregate" do
      person = Lotus::Person.new
      activity = Lotus::Activity.new

      person.stubs(:replies).returns(Lotus::Feed.new)

      person.replies.expects(:repost!).with(activity)
      person.replied_by! activity
    end
  end

  describe "#post!" do
    it "should post the activity to our activities aggregate" do
      person = Lotus::Person.new
      activity = Lotus::Activity.new

      person.stubs(:timeline).returns(Lotus::Feed.new)
      person.stubs(:activities).returns(Lotus::Feed.new)

      person.activities.expects(:post!).with(activity)
      person.timeline.stubs(:repost!).with(activity)
      person.post! activity
    end

    it "should repost the activity to our timeline" do
      person = Lotus::Person.new
      activity = Lotus::Activity.new

      person.stubs(:timeline).returns(Lotus::Feed.new)
      person.stubs(:activities).returns(Lotus::Feed.new)

      person.activities.stubs(:post!).with(activity)
      person.timeline.expects(:repost!).with(activity)
      person.post! activity
    end

    it "should create an activity if passed a hash" do
      activity = Lotus::Activity.new
      person = Lotus::Person.new

      person.stubs(:timeline).returns(Lotus::Feed.new)
      person.stubs(:activities).returns(Lotus::Feed.new)

      hash = {:content => "Hello"}

      person.activities.stubs(:post!).with(activity)
      person.timeline.stubs(:repost!).with(activity)

      Lotus::Activity.expects(:create!).with(hash).returns(activity)
      person.post! hash
    end
  end

  describe "#share!" do
    before do
      @person = Lotus::Person.new
      @person.stubs(:timeline).returns(Lotus::Feed.new)
      @person.stubs(:shared).returns(Lotus::Feed.new)
      @person.stubs(:activities).returns(Lotus::Feed.new)

      @person.shared.stubs(:repost!)
      @person.timeline.stubs(:repost!)
      @person.activities.stubs(:post!)
    end

    it "should repost the activity to our timeline aggregate" do
      activity = Lotus::Activity.new

      @person.timeline.expects(:repost!).with(activity)
      @person.share! activity
    end

    it "should repost the activity to our shared aggregate" do
      activity = Lotus::Activity.new

      @person.shared.expects(:repost!).with(activity)
      @person.share! activity
    end

    it "should post an activity to our activities with the share verb" do
      @person.activities.expects(:post!)
        .with(has_entry(:verb, :share))

      @person.share! Lotus::Activity.new
    end

    it "should post an activity to our activities with the correct actor" do
      activity = Lotus::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:actor_id  => @person.id,
                          :actor_type => 'Person'))

      @person.share! activity
    end

    it "should post an activity to our activities with shared activity" do
      activity = Lotus::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:external_object_id   => activity.id,
                          :external_object_type => 'Activity'))

      @person.share! activity
    end
  end

  describe "discover!" do
    it "should create an identity when author is discovered" do
      identity = Lotus::Identity.new

      Lotus::Identity.stubs(:find_by_identifier).returns(nil)
      Lotus.stubs(:discover_identity).with("wilkie@rstat.us").returns(identity)

      feed = Lotus::Feed.new(:authors => [Lotus::Person.new])
      feed.stubs(:save)

      Lotus.stubs(:discover_feed).with(identity).returns(feed)

      Lotus::Identity.expects(:create!).returns(identity)
      Lotus::Person.discover! "wilkie@rstat.us"
    end

    it "should return nil if identity cannot be discovered" do
      Lotus.stubs(:discover_identity).returns(nil)

      Lotus::Person.discover!("bogus@rstat.us").must_equal nil
    end

    it "should return nil if feed cannot be discovered" do
      identity = Lotus::Identity.new

      Lotus::Identity.stubs(:find_by_identifier).returns(nil)

      Lotus.stubs(:discover_identity).returns(identity)

      Lotus.stubs(:discover_feed).returns(nil)

      Lotus::Person.discover!("bogus@rstat.us").must_equal nil
    end

    it "should return Lotus::Person if one does not exist" do
      Lotus::Identity.stubs(:find_by_identifier).returns(nil)

      identity = Lotus::Identity.new
      Lotus.stubs(:discover_identity).with("wilkie@rstat.us").returns(identity)

      author = Lotus::Person.new
      feed = Lotus::Feed.new(:authors => [author])
      feed.stubs(:save)

      Lotus.stubs(:discover_feed).with(identity).returns(feed)

      Lotus::Person.discover!("wilkie@rstat.us").must_equal author
    end

    it "should return existing Lotus::Person if it can" do
      author = Lotus::Person.new
      identity = Lotus::Identity.new(:person => author)

      Lotus::Identity.stubs(:find_by_identifier).returns(identity)
      Lotus.stubs(:discover_identity).with("wilkie@rstat.us").returns(nil)

      Lotus::Person.discover!("wilkie@rstat.us").must_equal author
    end

    it "should assign the Identity outbox to the discovered feed" do
      identity = Lotus::Identity.new

      Lotus::Identity.stubs(:find_by_identifier).returns(nil)
      Lotus.stubs(:discover_identity).with("wilkie@rstat.us").returns(identity)

      feed = Lotus::Feed.new(:authors => [Lotus::Person.new])
      Lotus.stubs(:discover_feed).with(identity).returns(feed)

      Lotus::Identity.expects(:create!)
        .with(has_entry(:outbox, feed))
        .returns(identity)

      Lotus::Person.discover! "wilkie@rstat.us"
    end

    it "should assign the Identity person to the discovered Person" do
      identity = Lotus::Identity.new
      Lotus::Identity.stubs(:find_by_identifier).returns(nil)
      Lotus.stubs(:discover_identity).with("wilkie@rstat.us").returns(identity)

      author = Lotus::Person.new
      feed = Lotus::Feed.new(:authors => [author])
      Lotus.stubs(:discover_feed).with(identity).returns(feed)

      Lotus::Identity.expects(:create!)
        .with(has_entry(:person_id, author.id))
        .returns(identity)

      Lotus::Person.discover! "wilkie@rstat.us"
    end
  end

  describe "#discover_feed!" do
    it "should use Lotus to discover a feed from the identity" do
      author = Lotus::Person.create!
      identity = Lotus::Identity.create!(:person_id => author.id)

      Lotus.expects(:discover_feed).with(identity)

      author.discover_feed!
    end
  end

  describe "sanitize_params" do
    it "should allow extended name" do
      Lotus::Person.sanitize_params({:extended_name => {}})
        .keys.must_include :extended_name
    end

    it "should allow extended name's formatted field" do
      hash = {"extended_name" => {:formatted => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:extended_name][:formatted]
        .must_equal "foobar"
    end

    it "should allow extended name's given_name field" do
      hash = {"extended_name" => {:given_name => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:extended_name][:given_name]
        .must_equal "foobar"
    end

    it "should allow extended name's family_name field" do
      hash = {"extended_name" => {:family_name => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:extended_name][:family_name]
        .must_equal "foobar"
    end

    it "should allow extended name's honorific_prefix field" do
      hash = {"extended_name" => {:honorific_prefix => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:extended_name][:honorific_prefix]
        .must_equal "foobar"
    end

    it "should allow extended name's honorific_suffix field" do
      hash = {"extended_name" => {:honorific_suffix => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:extended_name][:honorific_suffix]
        .must_equal "foobar"
    end

    it "should allow extended name's middle_name field" do
      hash = {"extended_name" => {:middle_name => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:extended_name][:middle_name]
        .must_equal "foobar"
    end

    it "should allow organization" do
      Lotus::Person.sanitize_params({"organization" => {}})
        .keys.must_include :organization
    end

    it "should allow organization's name field" do
      hash = {"organization" => {:name => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:organization][:name]
        .must_equal "foobar"
    end

    it "should allow organization's department field" do
      hash = {"organization" => {:department => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:organization][:department]
        .must_equal "foobar"
    end

    it "should allow organization's title field" do
      hash = {"organization" => {:title => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:organization][:title]
        .must_equal "foobar"
    end

    it "should allow organization's type field" do
      hash = {"organization" => {:type => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:organization][:type]
        .must_equal "foobar"
    end

    it "should allow organization's start_date field" do
      hash = {"organization" => {:start_date => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:organization][:start_date]
        .must_equal "foobar"
    end

    it "should allow organization's end_date field" do
      hash = {"organization" => {:end_date => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:organization][:end_date]
        .must_equal "foobar"
    end

    it "should allow organization's description field" do
      hash = {"organization" => {:description => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:organization][:description]
        .must_equal "foobar"
    end

    it "should allow address" do
      Lotus::Person.sanitize_params({"address" => {}})
        .keys.must_include :address
    end

    it "should allow address's formatted field" do
      hash = {"address" => {:formatted => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:address][:formatted]
        .must_equal "foobar"
    end

    it "should allow address's street_address field" do
      hash = {"address" => {:street_address => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:address][:street_address]
        .must_equal "foobar"
    end

    it "should allow address's locality field" do
      hash = {"address" => {:locality => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:address][:locality]
        .must_equal "foobar"
    end

    it "should allow address's region field" do
      hash = {"address" => {:region => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:address][:region]
        .must_equal "foobar"
    end

    it "should allow address's country field" do
      hash = {"address" => {:country => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:address][:country]
        .must_equal "foobar"
    end

    it "should allow address's postal_code field" do
      hash = {"address" => {:postal_code => "foobar"}}
      Lotus::Person.sanitize_params(hash)[:address][:postal_code]
        .must_equal "foobar"
    end

    it "should allow Lotus::Person keys" do
      hash = {}
      Lotus::Person.keys.keys.each do |k|
        next if ["extended_name", "organization", "address", "_id"].include? k
        hash[k] = "foobar"
      end

      hash = Lotus::Person.sanitize_params(hash)

      Lotus::Person.keys.keys.each do |k|
        next if ["extended_name", "organization", "address", "_id"].include? k
        hash[k.intern].must_equal "foobar"
      end
    end

    it "should convert strings to symbols" do
      hash = {}
      Lotus::Person.keys.keys.each do |k|
        next if ["extended_name", "organization", "address", "_id"].include? k
        hash[k] = "foobar"
      end

      hash = Lotus::Person.sanitize_params(hash)

      Lotus::Person.keys.keys.each do |k|
        next if ["extended_name", "organization", "address", "_id"].include? k
        hash[k.intern].must_equal "foobar"
      end
    end

    it "should not allow _id" do
      hash = {"_id" => "bogus"}
      hash = Lotus::Person.sanitize_params(hash)
      hash.keys.wont_include :_id
    end

    it "should not allow arbitrary keys" do
      hash = {:bogus => "foobar"}

      hash = Lotus::Person.sanitize_params(hash)

      hash.keys.wont_include :bogus
    end
  end

  describe "#short_name" do
    it "should use display_name over all else" do
      author = Lotus::Person.create(:display_name => "display",
                             :name => "name",
                             :preferred_username => "preferred",
                             :nickname => "nickname",
                             :uid => "unique")

      author.short_name.must_equal "display"
    end

    it "should use name over all else when display name doesn't exist" do
      author = Lotus::Person.create(:name => "name",
                             :preferred_username => "preferred",
                             :nickname => "nickname",
                             :uid => "unique")

      author.short_name.must_equal "name"
    end

    it "should use preferred_username when name and display_name don't exist" do
      author = Lotus::Person.create(:preferred_username => "preferred",
                             :nickname => "nickname",
                             :uid => "unique")

      author.short_name.must_equal "preferred"
    end

    it "should use nickname when it exists and others do not" do
      author = Lotus::Person.create(:nickname => "nickname",
                             :uid => "unique")

      author.short_name.must_equal "nickname"
    end

    it "should use uid when all else fails" do
      author = Lotus::Person.create(:uid => "unique")

      author.short_name.must_equal "unique"
    end
  end

  describe "#update_avatar!" do
    it "should pass through the url to Avatar.from_url!" do
      Lotus::Avatar.expects(:from_url!).with(anything, "avatar_url", anything)

      author = Lotus::Person.create
      author.update_avatar! "avatar_url"
    end

    it "should pass through author instance to Avatar.from_url!" do
      author = Lotus::Person.create

      Lotus::Avatar.expects(:from_url!).with(author, anything, anything)

      author.update_avatar! "avatar_url"
    end

    it "should pass through appropriate avatar size" do
      Lotus::Avatar.expects(:from_url!)
        .with(anything, anything, has_entry(:sizes, [[48, 48]]))

      author = Lotus::Person.create
      author.update_avatar! "avatar_url"
    end
  end
end

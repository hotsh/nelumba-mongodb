require_relative 'helper'

describe Nelumba::Person do
  describe "Schema" do
    it "should have one authorization" do
      Nelumba::Person.has_one?(:authorization).must_equal true
    end

    it "should have one identity" do
      Nelumba::Person.has_one?(:identity).must_equal true
    end

    it "should have one avatar" do
      Nelumba::Person.has_one?(:avatar).must_equal true
    end

    it "should have a uid" do
      Nelumba::Person.keys.keys.must_include "uid"
    end

    it "should have a nickname" do
      Nelumba::Person.keys.keys.must_include "nickname"
    end

    it "should have an extended_name" do
      Nelumba::Person.keys.keys.must_include "extended_name"
    end

    it "should have a url" do
      Nelumba::Person.keys.keys.must_include "url"
    end

    it "should have an email" do
      Nelumba::Person.keys.keys.must_include "email"
    end

    it "should have a name" do
      Nelumba::Person.keys.keys.must_include "name"
    end

    it "should have an organization" do
      Nelumba::Person.keys.keys.must_include "organization"
    end

    it "should have an address" do
      Nelumba::Person.keys.keys.must_include "address"
    end

    it "should have a gender" do
      Nelumba::Person.keys.keys.must_include "gender"
    end

    it "should have a note" do
      Nelumba::Person.keys.keys.must_include "note"
    end

    it "should have a display_name" do
      Nelumba::Person.keys.keys.must_include "display_name"
    end

    it "should have a preferred_username" do
      Nelumba::Person.keys.keys.must_include "preferred_username"
    end

    it "should have a birthday" do
      Nelumba::Person.keys.keys.must_include "birthday"
    end

    it "should have an anniversary" do
      Nelumba::Person.keys.keys.must_include "anniversary"
    end

    it "should have a published" do
      Nelumba::Person.keys.keys.must_include "published"
    end

    it "should have a updated" do
      Nelumba::Person.keys.keys.must_include "updated"
    end

    it "should have an activities id" do
      Nelumba::Person.keys.keys.must_include "activities_id"
    end

    it "should have a timeline id" do
      Nelumba::Person.keys.keys.must_include "timeline_id"
    end

    it "should have a favorites id" do
      Nelumba::Person.keys.keys.must_include "favorites_id"
    end

    it "should have a shared id" do
      Nelumba::Person.keys.keys.must_include "shared_id"
    end

    it "should have a replies id" do
      Nelumba::Person.keys.keys.must_include "replies_id"
    end

    it "should have a mentions id" do
      Nelumba::Person.keys.keys.must_include "mentions_id"
    end

    it "should have a following_ids array" do
      Nelumba::Person.keys.keys.must_include "following_ids"
    end

    it "should have a followers_ids array" do
      Nelumba::Person.keys.keys.must_include "followers_ids"
    end
  end

  describe "create" do
    before do
      @author = Nelumba::Person.new
      Nelumba::Person.stubs(:create).returns(@author)

      @aggregate = Nelumba::Feed.new
      Nelumba::Feed.stubs(:create).returns(@aggregate)

      @person = Nelumba::Person.new
    end
  end

  describe "new_local" do
    before do
      @aggregate = Nelumba::Feed.new
      Nelumba::Feed.stubs(:new).returns(@aggregate)

      @person = Nelumba::Person.new
      Nelumba::Person.stubs(:new).returns(@person)
    end

    it "should create an activities aggregate upon creation" do
      @person.expects(:activities_id=).with(@aggregate.id)
      Nelumba::Person.new_local "wilkie", "www.example.com", nil, true
    end

    it "should create a timeline aggregate upon creation" do
      @person.expects(:timeline_id=).with(@aggregate.id)
      Nelumba::Person.new_local "wilkie", "www.example.com", nil, true
    end

    it "should create a shared aggregate upon creation" do
      @person.expects(:shared_id=).with(@aggregate.id)
      Nelumba::Person.new_local "wilkie", "www.example.com", nil, true
    end

    it "should create a favorites aggregate upon creation" do
      @person.expects(:favorites_id=).with(@aggregate.id)
      Nelumba::Person.new_local "wilkie", "www.example.com", nil, true
    end

    it "should create a replies aggregate upon creation" do
      @person.expects(:replies_id=).with(@aggregate.id)
      Nelumba::Person.new_local "wilkie", "www.example.com", nil, true
    end

    it "should create a mentions aggregate upon creation" do
      @person.expects(:mentions_id=).with(@aggregate.id)
      Nelumba::Person.new_local "wilkie", "www.example.com", nil, true
    end

    it "should set the url to a valid url for the given domain" do
      @person.expects(:url=).with("http://status.example.com/people/#{@person.id}")
      Nelumba::Person.new_local "wilkie", "status.example.com", nil, false
    end

    it "should respect ssl requirements in the url" do
      @person.expects(:url=).with("https://status.example.com/people/#{@person.id}")
      Nelumba::Person.new_local "wilkie", "status.example.com", nil, true
    end
  end

  describe "#follow!" do
    before do
      @person = Nelumba::Person.new
      @person.stubs(:save)

      timeline = Nelumba::Feed.new
      timeline.stubs(:follow!)
      timeline.stubs(:save)
      @person.stubs(:timeline).returns(timeline)

      activities = Nelumba::Feed.new
      activities.stubs(:save)
      activities.stubs(:post!)
      @person.stubs(:activities).returns(activities)

      @author = Nelumba::Person.new({:local => false})
      @author.stubs(:local?).returns(false)

      feed = Nelumba::Feed.new
      feed.stubs(:save)

      outbox = Nelumba::Feed.new
      outbox.stubs(:save)
      outbox.stubs(:feed).returns(feed)

      identity = Nelumba::Identity.new(:outbox_id => outbox.id,
                              :author_id => @author.id)
      identity.stubs(:outbox).returns(outbox)
      identity.stubs(:person).returns(@author)
      identity.stubs(:save)

      @author.stubs(:identity).returns(identity)
      @author.stubs(:save)

      @person.stubs(:author).returns(@author)
    end

    it "should add the given remote Nelumba::Person to the following list" do
      @person.follow! @author
      @person.following_ids.must_include @author.id
    end

    it "should allow an Nelumba::Identity to be given" do
      @person.follow! @author.identity
      @person.following_ids.must_include @author.id
    end

    it "should add the given local Nelumba::Person to the following list" do
      @author.stubs(:local?).returns(true)

      @author.stubs(:followed_by!)

      @person.follow! @author
      @person.following_ids.must_include @author.id
    end

    it "should add self to the local Nelumba::Person's followers list" do
      @author.stubs(:local?).returns(true)

      @author.expects(:followed_by!)

      @person.follow! @author
    end
  end

  describe "#unfollow!" do
    before do
      @person = Nelumba::Person.new
      @person.stubs(:save)

      timeline = Nelumba::Feed.new
      timeline.stubs(:follow!)
      timeline.stubs(:save)
      @person.stubs(:timeline).returns(timeline)

      activities = Nelumba::Feed.new
      activities.stubs(:save)
      activities.stubs(:post!)
      @person.stubs(:activities).returns(activities)

      @author = Nelumba::Person.new

      feed = Nelumba::Feed.new
      feed.stubs(:save)

      outbox = Nelumba::Feed.new
      outbox.stubs(:save)
      outbox.stubs(:feed).returns(feed)

      identity = Nelumba::Identity.new(:outbox_id => outbox.id,
                              :author_id => @author.id)
      identity.stubs(:outbox).returns(outbox)
      identity.stubs(:person).returns(@author)
      identity.stubs(:save)

      @author.stubs(:identity).returns(identity)
      @author.stubs(:save)

      @person.following_ids = [@author.id]
    end

    it "should remove the given remote Nelumba::Person from the following list" do
      @person.unfollow! @author
      @person.following_ids.wont_include @author.id
    end

    it "should allow an Nelumba::Identity to be given" do
      @person.unfollow! @author.identity
      @person.following_ids.wont_include @author.id
    end

    it "should remove the given local Nelumba::Person from the following list" do
      @author.stubs(:local).returns(true)

      local_person = Nelumba::Person.new
      local_person.stubs(:save)
      @author.stubs(:person).returns(local_person)

      local_person.stubs(:unfollowed_by!)

      @person.unfollow! @author
      @person.following_ids.wont_include @author.id
    end

    it "should remove self from the local Nelumba::Person's followers list" do
      @author.stubs(:local?).returns(true)

      @author.expects(:unfollowed_by!)

      @person.unfollow! @author
    end
  end

  describe "#followed_by!" do
    before do
      activities = Nelumba::Feed.new
      activities.stubs(:followed_by!)

      @person = Nelumba::Person.new
      @person.stubs(:save)
      @person.stubs(:activities).returns(activities)

      @author = Nelumba::Person.new
      @author.stubs(:save)

      aggregate = Nelumba::Feed.new
      aggregate.stubs(:feed).returns(Nelumba::Feed.new)
      aggregate.stubs(:save)

      aggregate_in = Nelumba::Feed.new
      aggregate_in.stubs(:feed).returns(Nelumba::Feed.new)
      aggregate_in.stubs(:save)

      @identity = Nelumba::Identity.new(:outbox_id => aggregate.id,
                               :inbox_id  => aggregate_in.id,
                               :author_id => @author.id)

      @identity.stubs(:person).returns(@author)
      @identity.stubs(:outbox).returns(aggregate)
      @identity.stubs(:inbox).returns(aggregate_in)
      @author.stubs(:identity).returns(@identity)
    end

    it "should add the given remote Nelumba::Person to our followers list" do
      @person.followed_by! @author
      @person.followers_ids.must_include @author.id
    end

    it "should add the given Nelumba::Identity to our followers list" do
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
      activities = Nelumba::Feed.new
      activities.stubs(:unfollowed_by!)

      @person = Nelumba::Person.new
      @person.stubs(:save)
      @person.stubs(:activities).returns(activities)

      @author = Nelumba::Person.new
      @author.stubs(:save)

      aggregate = Nelumba::Feed.new
      aggregate.stubs(:save)

      aggregate_in = Nelumba::Feed.new
      aggregate_in.stubs(:save)

      @identity = Nelumba::Identity.new(:outbox_id => aggregate.id,
                               :inbox_id  => aggregate_in.id,
                               :author_id => @author.id)

      @identity.stubs(:person).returns(@author)
      @identity.stubs(:outbox).returns(aggregate)
      @identity.stubs(:inbox).returns(aggregate_in)
      @author.stubs(:identity).returns(@identity)
    end

    it "should remove the given remote Nelumba::Person from our followers list" do
      @person.unfollowed_by! @author
      @person.followers_ids.wont_include @author.id
    end

    it "should remove the given Nelumba::Identity from our followers list" do
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
      activities = Nelumba::Feed.new
      activities.stubs(:post!)
      favorites = Nelumba::Feed.new
      favorites.stubs(:repost!)

      @person = Nelumba::Person.new
      @person.stubs(:activities).returns(activities)
      @person.stubs(:favorites).returns(favorites)
    end

    it "should repost the given activity to our favorites aggregate" do
      activity = Nelumba::Activity.new

      @person.favorites.expects(:repost!).with(activity)
      @person.favorite! activity
    end

    it "should post an activity to our activities with favorite verb" do
      activity = Nelumba::Activity.new

      @person.activities.expects(:post!).with(has_entry(:verb, :favorite))
      @person.favorite! activity
    end

    it "should post an activity to our activities with our author as actor" do
      activity = Nelumba::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:actor_id   => @person.id,
                          :actor_type => 'Person'))

      @person.favorite! activity
    end

    it "should post an activity to our activities with favorited activity" do
      activity = Nelumba::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:external_object_id   => activity.id,
                          :external_object_type => 'Activity'))

      @person.favorite! activity
    end
  end

  describe "#unfavorite!" do
    before do
      activities = Nelumba::Feed.new
      activities.stubs(:post!)
      favorites = Nelumba::Feed.new
      favorites.stubs(:delete!)

      author = Nelumba::Person.new

      @person = Nelumba::Person.new
      @person.stubs(:activities).returns(activities)
      @person.stubs(:favorites).returns(favorites)
      @person.stubs(:author).returns(author)
    end

    it "should repost the given activity to our favorites aggregate" do
      activity = Nelumba::Activity.new

      @person.favorites.expects(:delete!).with(activity)
      @person.unfavorite! activity
    end

    it "should post an activity to our activities with favorite verb" do
      activity = Nelumba::Activity.new

      @person.activities.expects(:post!).with(has_entry(:verb, :unfavorite))
      @person.unfavorite! activity
    end

    it "should post an activity to our activities with our author as actor" do
      activity = Nelumba::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:actor_id   => @person.id,
                          :actor_type => 'Person'))

      @person.unfavorite! activity
    end

    it "should post an activity to our activities with favorited activity" do
      activity = Nelumba::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:external_object_id   => activity.id,
                          :external_object_type => 'Activity'))

      @person.unfavorite! activity
    end
  end

  describe "#mentioned_by!" do
    it "should repost the activity to our mentions aggregate" do
      person = Nelumba::Person.new
      activity = Nelumba::Activity.new

      person.stubs(:mentions).returns(Nelumba::Feed.new)

      person.mentions.expects(:repost!).with(activity)
      person.mentioned_by! activity
    end
  end

  describe "#replied_by!" do
    it "should repost the activity to our replies aggregate" do
      person = Nelumba::Person.new
      activity = Nelumba::Activity.new

      person.stubs(:replies).returns(Nelumba::Feed.new)

      person.replies.expects(:repost!).with(activity)
      person.replied_by! activity
    end
  end

  describe "#post!" do
    it "should post the activity to our activities aggregate" do
      person = Nelumba::Person.new
      activity = Nelumba::Activity.new

      person.stubs(:timeline).returns(Nelumba::Feed.new)
      person.stubs(:activities).returns(Nelumba::Feed.new)

      person.activities.expects(:post!).with(activity)
      person.timeline.stubs(:repost!).with(activity)
      person.post! activity
    end

    it "should repost the activity to our timeline" do
      person = Nelumba::Person.new
      activity = Nelumba::Activity.new

      person.stubs(:timeline).returns(Nelumba::Feed.new)
      person.stubs(:activities).returns(Nelumba::Feed.new)

      person.activities.stubs(:post!).with(activity)
      person.timeline.expects(:repost!).with(activity)
      person.post! activity
    end

    it "should create an activity if passed a hash" do
      activity = Nelumba::Activity.new
      person = Nelumba::Person.new

      person.stubs(:timeline).returns(Nelumba::Feed.new)
      person.stubs(:activities).returns(Nelumba::Feed.new)

      hash = {:content => "Hello"}

      person.activities.stubs(:post!).with(activity)
      person.timeline.stubs(:repost!).with(activity)

      Nelumba::Activity.expects(:create!).with(hash).returns(activity)
      person.post! hash
    end
  end

  describe "#share!" do
    before do
      @person = Nelumba::Person.new
      @person.stubs(:timeline).returns(Nelumba::Feed.new)
      @person.stubs(:shared).returns(Nelumba::Feed.new)
      @person.stubs(:activities).returns(Nelumba::Feed.new)

      @person.shared.stubs(:repost!)
      @person.timeline.stubs(:repost!)
      @person.activities.stubs(:post!)
    end

    it "should repost the activity to our timeline aggregate" do
      activity = Nelumba::Activity.new

      @person.timeline.expects(:repost!).with(activity)
      @person.share! activity
    end

    it "should repost the activity to our shared aggregate" do
      activity = Nelumba::Activity.new

      @person.shared.expects(:repost!).with(activity)
      @person.share! activity
    end

    it "should post an activity to our activities with the share verb" do
      @person.activities.expects(:post!)
        .with(has_entry(:verb, :share))

      @person.share! Nelumba::Activity.new
    end

    it "should post an activity to our activities with the correct actor" do
      activity = Nelumba::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:actor_id  => @person.id,
                          :actor_type => 'Person'))

      @person.share! activity
    end

    it "should post an activity to our activities with shared activity" do
      activity = Nelumba::Activity.new

      @person.activities.expects(:post!)
        .with(has_entries(:external_object_id   => activity.id,
                          :external_object_type => 'Activity'))

      @person.share! activity
    end
  end

  describe "discover!" do
    it "should create an identity when author is discovered" do
      identity = Nelumba::Identity.new

      Nelumba::Identity.stubs(:find_by_identifier).returns(nil)
      Nelumba::Discover.stubs(:identity).with("wilkie@rstat.us").returns(identity)

      feed = Nelumba::Feed.new(:authors => [Nelumba::Person.new])
      feed.stubs(:save)

      Nelumba::Discover.stubs(:feed).with(identity).returns(feed)

      Nelumba::Identity.expects(:create!).returns(identity)
      Nelumba::Person.discover! "wilkie@rstat.us"
    end

    it "should return nil if identity cannot be discovered" do
      Nelumba::Discover.stubs(:identity).returns(nil)

      Nelumba::Person.discover!("bogus@rstat.us").must_equal nil
    end

    it "should return nil if feed cannot be discovered" do
      identity = Nelumba::Identity.new

      Nelumba::Identity.stubs(:find_by_identifier).returns(nil)

      Nelumba::Discover.stubs(:identity).returns(identity)

      Nelumba::Discover.stubs(:feed).returns(nil)

      Nelumba::Person.discover!("bogus@rstat.us").must_equal nil
    end

    it "should return Nelumba::Person if one does not exist" do
      Nelumba::Identity.stubs(:find_by_identifier).returns(nil)

      identity = Nelumba::Identity.new
      Nelumba::Discover.stubs(:identity).with("wilkie@rstat.us").returns(identity)

      author = Nelumba::Person.new
      feed = Nelumba::Feed.new(:authors => [author])
      feed.stubs(:save)

      Nelumba::Discover.stubs(:feed).with(identity).returns(feed)

      Nelumba::Person.discover!("wilkie@rstat.us").must_equal author
    end

    it "should return existing Nelumba::Person if it can" do
      author = Nelumba::Person.new
      identity = Nelumba::Identity.new(:person => author)

      Nelumba::Identity.stubs(:find_by_identifier).returns(identity)
      Nelumba::Discover.stubs(:identity).with("wilkie@rstat.us").returns(nil)

      Nelumba::Person.discover!("wilkie@rstat.us").must_equal author
    end

    it "should assign the Identity outbox to the discovered feed" do
      identity = Nelumba::Identity.new

      Nelumba::Identity.stubs(:find_by_identifier).returns(nil)
      Nelumba::Discover.stubs(:identity).with("wilkie@rstat.us").returns(identity)

      feed = Nelumba::Feed.new(:authors => [Nelumba::Person.new])
      Nelumba::Discover.stubs(:feed).with(identity).returns(feed)

      Nelumba::Identity.expects(:create!)
        .with(has_entry(:outbox, feed))
        .returns(identity)

      Nelumba::Person.discover! "wilkie@rstat.us"
    end

    it "should assign the Identity person to the discovered Person" do
      identity = Nelumba::Identity.new
      Nelumba::Identity.stubs(:find_by_identifier).returns(nil)
      Nelumba::Discover.stubs(:identity).with("wilkie@rstat.us").returns(identity)

      author = Nelumba::Person.new
      feed = Nelumba::Feed.new(:authors => [author])
      Nelumba::Discover.stubs(:feed).with(identity).returns(feed)

      Nelumba::Identity.expects(:create!)
        .with(has_entry(:person_id, author.id))
        .returns(identity)

      Nelumba::Person.discover! "wilkie@rstat.us"
    end
  end

  describe "#discover_feed!" do
    it "should use Nelumba to discover a feed from the identity" do
      author = Nelumba::Person.create!
      identity = Nelumba::Identity.create!(:person_id => author.id)

      Nelumba::Discover.expects(:feed).with(identity)

      author.discover_feed!
    end
  end

  describe "sanitize_params" do
    it "should allow extended name" do
      Nelumba::Person.sanitize_params({:extended_name => {}})
        .keys.must_include :extended_name
    end

    it "should allow extended name's formatted field" do
      hash = {"extended_name" => {:formatted => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:extended_name][:formatted]
        .must_equal "foobar"
    end

    it "should allow extended name's given_name field" do
      hash = {"extended_name" => {:given_name => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:extended_name][:given_name]
        .must_equal "foobar"
    end

    it "should allow extended name's family_name field" do
      hash = {"extended_name" => {:family_name => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:extended_name][:family_name]
        .must_equal "foobar"
    end

    it "should allow extended name's honorific_prefix field" do
      hash = {"extended_name" => {:honorific_prefix => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:extended_name][:honorific_prefix]
        .must_equal "foobar"
    end

    it "should allow extended name's honorific_suffix field" do
      hash = {"extended_name" => {:honorific_suffix => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:extended_name][:honorific_suffix]
        .must_equal "foobar"
    end

    it "should allow extended name's middle_name field" do
      hash = {"extended_name" => {:middle_name => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:extended_name][:middle_name]
        .must_equal "foobar"
    end

    it "should allow organization" do
      Nelumba::Person.sanitize_params({"organization" => {}})
        .keys.must_include :organization
    end

    it "should allow organization's name field" do
      hash = {"organization" => {:name => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:organization][:name]
        .must_equal "foobar"
    end

    it "should allow organization's department field" do
      hash = {"organization" => {:department => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:organization][:department]
        .must_equal "foobar"
    end

    it "should allow organization's title field" do
      hash = {"organization" => {:title => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:organization][:title]
        .must_equal "foobar"
    end

    it "should allow organization's type field" do
      hash = {"organization" => {:type => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:organization][:type]
        .must_equal "foobar"
    end

    it "should allow organization's start_date field" do
      hash = {"organization" => {:start_date => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:organization][:start_date]
        .must_equal "foobar"
    end

    it "should allow organization's end_date field" do
      hash = {"organization" => {:end_date => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:organization][:end_date]
        .must_equal "foobar"
    end

    it "should allow organization's description field" do
      hash = {"organization" => {:description => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:organization][:description]
        .must_equal "foobar"
    end

    it "should allow address" do
      Nelumba::Person.sanitize_params({"address" => {}})
        .keys.must_include :address
    end

    it "should allow address's formatted field" do
      hash = {"address" => {:formatted => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:address][:formatted]
        .must_equal "foobar"
    end

    it "should allow address's street_address field" do
      hash = {"address" => {:street_address => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:address][:street_address]
        .must_equal "foobar"
    end

    it "should allow address's locality field" do
      hash = {"address" => {:locality => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:address][:locality]
        .must_equal "foobar"
    end

    it "should allow address's region field" do
      hash = {"address" => {:region => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:address][:region]
        .must_equal "foobar"
    end

    it "should allow address's country field" do
      hash = {"address" => {:country => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:address][:country]
        .must_equal "foobar"
    end

    it "should allow address's postal_code field" do
      hash = {"address" => {:postal_code => "foobar"}}
      Nelumba::Person.sanitize_params(hash)[:address][:postal_code]
        .must_equal "foobar"
    end

    it "should allow Nelumba::Person keys" do
      hash = {}
      Nelumba::Person.keys.keys.each do |k|
        next if ["extended_name", "organization", "address", "_id"].include? k
        hash[k] = "foobar"
      end

      hash = Nelumba::Person.sanitize_params(hash)

      Nelumba::Person.keys.keys.each do |k|
        next if ["extended_name", "organization", "address", "_id"].include? k
        hash[k.intern].must_equal "foobar"
      end
    end

    it "should convert strings to symbols" do
      hash = {}
      Nelumba::Person.keys.keys.each do |k|
        next if ["extended_name", "organization", "address", "_id"].include? k
        hash[k] = "foobar"
      end

      hash = Nelumba::Person.sanitize_params(hash)

      Nelumba::Person.keys.keys.each do |k|
        next if ["extended_name", "organization", "address", "_id"].include? k
        hash[k.intern].must_equal "foobar"
      end
    end

    it "should not allow _id" do
      hash = {"_id" => "bogus"}
      hash = Nelumba::Person.sanitize_params(hash)
      hash.keys.wont_include :_id
    end

    it "should not allow arbitrary keys" do
      hash = {:bogus => "foobar"}

      hash = Nelumba::Person.sanitize_params(hash)

      hash.keys.wont_include :bogus
    end
  end

  describe "#update_avatar!" do
    it "should pass through the url to Avatar.from_url!" do
      Nelumba::Avatar.expects(:from_url!).with(anything, "avatar_url", anything)

      author = Nelumba::Person.create
      author.update_avatar! "avatar_url"
    end

    it "should pass through author instance to Avatar.from_url!" do
      author = Nelumba::Person.create

      Nelumba::Avatar.expects(:from_url!).with(author, anything, anything)

      author.update_avatar! "avatar_url"
    end

    it "should pass through appropriate avatar size" do
      Nelumba::Avatar.expects(:from_url!)
        .with(anything, anything, has_entry(:sizes, [[48, 48]]))

      author = Nelumba::Person.create
      author.update_avatar! "avatar_url"
    end
  end
end

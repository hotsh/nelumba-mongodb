require_relative 'helper'

describe Lotus::Person do
  describe "Schema" do
    it "should have an authorization id" do
      Lotus::Person.keys.keys.must_include "authorization_id"
    end

    it "should have an author id" do
      Lotus::Person.keys.keys.must_include "author_id"
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
      @author = Lotus::Author.new
      Lotus::Author.stubs(:create).returns(@author)

      @aggregate = Lotus::Aggregate.new
      Lotus::Aggregate.stubs(:create).returns(@aggregate)

      @person = Lotus::Person.new
    end

    it "should create an author upon creation" do
      @person.expects(:author=).with(@author)
      @person.run_callbacks :create
    end

    it "should create an activities aggregate upon creation" do
      @person.expects(:activities=).with(@aggregate)
      @person.run_callbacks :create
    end

    it "should create a timeline aggregate upon creation" do
      @person.expects(:timeline=).with(@aggregate)
      @person.run_callbacks :create
    end

    it "should create a shared aggregate upon creation" do
      @person.expects(:shared=).with(@aggregate)
      @person.run_callbacks :create
    end

    it "should create a favorites aggregate upon creation" do
      @person.expects(:favorites=).with(@aggregate)
      @person.run_callbacks :create
    end

    it "should create a replies aggregate upon creation" do
      @person.expects(:replies=).with(@aggregate)
      @person.run_callbacks :create
    end

    it "should create a mentions aggregate upon creation" do
      @person.expects(:mentions=).with(@aggregate)
      @person.run_callbacks :create
    end
  end

  describe "#follow!" do
    before do
      @person = Lotus::Person.new
      @person.stubs(:save)

      timeline = Lotus::Aggregate.new
      timeline.stubs(:follow!)
      timeline.stubs(:save)
      @person.stubs(:timeline).returns(timeline)

      activities = Lotus::Aggregate.new
      activities.stubs(:save)
      activities.stubs(:post!)
      @person.stubs(:activities).returns(activities)

      @author = Lotus::Author.new({:local => false})

      feed = Lotus::Feed.new
      feed.stubs(:save)

      outbox = Lotus::Aggregate.new
      outbox.stubs(:save)
      outbox.stubs(:feed).returns(feed)

      identity = Lotus::Identity.new(:outbox_id => outbox.id,
                              :author_id => @author.id)
      identity.stubs(:outbox).returns(outbox)
      identity.stubs(:author).returns(@author)
      identity.stubs(:save)

      @author.stubs(:identity).returns(identity)
      @author.stubs(:save)

      @person.stubs(:author).returns(@author)
    end

    it "should add the given remote Lotus::Author to the following list" do
      @person.follow! @author
      @person.following_ids.must_include @author.id
    end

    it "should allow an Lotus::Identity to be given" do
      @person.follow! @author.identity
      @person.following_ids.must_include @author.id
    end

    it "should add the given local Lotus::Author to the following list" do
      @author.local = true

      local_person = Lotus::Person.new
      local_person.stubs(:save)
      @author.stubs(:person).returns(local_person)

      local_person.stubs(:followed_by!)

      @person.follow! @author
      @person.following_ids.must_include @author.id
    end

    it "should add self to the local Lotus::Author's followers list" do
      @author.local = true

      local_person = Lotus::Person.new
      local_person.stubs(:save)
      @author.stubs(:person).returns(local_person)

      local_person.expects(:followed_by!)

      @person.follow! @author
    end
  end

  describe "#unfollow!" do
    before do
      @person = Lotus::Person.new
      @person.stubs(:save)

      timeline = Lotus::Aggregate.new
      timeline.stubs(:follow!)
      timeline.stubs(:save)
      @person.stubs(:timeline).returns(timeline)

      activities = Lotus::Aggregate.new
      activities.stubs(:save)
      activities.stubs(:post!)
      @person.stubs(:activities).returns(activities)

      @author = Lotus::Author.new({:local => false})

      feed = Lotus::Feed.new
      feed.stubs(:save)

      outbox = Lotus::Aggregate.new
      outbox.stubs(:save)
      outbox.stubs(:feed).returns(feed)

      identity = Lotus::Identity.new(:outbox_id => outbox.id,
                              :author_id => @author.id)
      identity.stubs(:outbox).returns(outbox)
      identity.stubs(:author).returns(@author)
      identity.stubs(:save)

      @author.stubs(:identity).returns(identity)
      @author.stubs(:save)

      @person.stubs(:author).returns(@author)

      @person.following_ids = [@author.id]
    end

    it "should remove the given remote Lotus::Author from the following list" do
      @person.unfollow! @author
      @person.following_ids.wont_include @author.id
    end

    it "should allow an Lotus::Identity to be given" do
      @person.unfollow! @author.identity
      @person.following_ids.wont_include @author.id
    end

    it "should remove the given local Lotus::Author from the following list" do
      @author.local = true

      local_person = Lotus::Person.new
      local_person.stubs(:save)
      @author.stubs(:person).returns(local_person)

      local_person.stubs(:unfollowed_by!)

      @person.unfollow! @author
      @person.following_ids.wont_include @author.id
    end

    it "should remove self from the local Lotus::Author's followers list" do
      @author.local = true

      local_person = Lotus::Person.new
      local_person.stubs(:save)
      @author.stubs(:person).returns(local_person)

      local_person.expects(:unfollowed_by!)

      @person.unfollow! @author
    end
  end

  describe "#followed_by!" do
    before do
      activities = Lotus::Aggregate.new
      activities.stubs(:followed_by!)

      @person = Lotus::Person.new
      @person.stubs(:save)
      @person.stubs(:activities).returns(activities)

      @author = Lotus::Author.new
      @author.stubs(:save)

      aggregate = Lotus::Aggregate.new
      aggregate.stubs(:feed).returns(Lotus::Feed.new)
      aggregate.stubs(:save)

      aggregate_in = Lotus::Aggregate.new
      aggregate_in.stubs(:feed).returns(Lotus::Feed.new)
      aggregate_in.stubs(:save)

      @identity = Lotus::Identity.new(:outbox_id => aggregate.id,
                               :inbox_id  => aggregate_in.id,
                               :author_id => @author.id)

      @identity.stubs(:author).returns(@author)
      @identity.stubs(:outbox).returns(aggregate)
      @identity.stubs(:inbox).returns(aggregate_in)
      @author.stubs(:identity).returns(@identity)
    end

    it "should add the given remote Lotus::Author to our followers list" do
      @person.followed_by! @author
      @person.followers_ids.must_include @author.id
    end

    it "should add the given Lotus::Identity to our followers list" do
      @person.followed_by! @identity
      @person.followers_ids.must_include @author.id
    end

    it "should add outbox to activities' followers list" do
      @person.activities.expects(:followed_by!).with(@identity.inbox.feed)
      @person.followed_by! @author
    end
  end

  describe "#unfollowed_by!" do
    before do
      activities = Lotus::Aggregate.new
      activities.stubs(:unfollowed_by!)

      @person = Lotus::Person.new
      @person.stubs(:save)
      @person.stubs(:activities).returns(activities)

      @author = Lotus::Author.new
      @author.stubs(:save)

      aggregate = Lotus::Aggregate.new
      aggregate.stubs(:feed).returns(Lotus::Feed.new)
      aggregate.stubs(:save)

      aggregate_in = Lotus::Aggregate.new
      aggregate_in.stubs(:feed).returns(Lotus::Feed.new)
      aggregate_in.stubs(:save)

      @identity = Lotus::Identity.new(:outbox_id => aggregate.id,
                               :inbox_id  => aggregate_in.id,
                               :author_id => @author.id)

      @identity.stubs(:author).returns(@author)
      @identity.stubs(:outbox).returns(aggregate)
      @identity.stubs(:inbox).returns(aggregate_in)
      @author.stubs(:identity).returns(@identity)
    end

    it "should remove the given remote Lotus::Author from our followers list" do
      @person.unfollowed_by! @author
      @person.followers_ids.wont_include @author.id
    end

    it "should remove the given Lotus::Identity from our followers list" do
      @person.unfollowed_by! @identity
      @person.followers_ids.wont_include @author.id
    end

    it "should remove outbox from activities' followers list" do
      @person.activities.expects(:unfollowed_by!).with(@identity.inbox.feed)
      @person.unfollowed_by! @author
    end
  end

  describe "#favorite!" do
    before do
      activities = Lotus::Aggregate.new
      activities.stubs(:post!)
      favorites = Lotus::Aggregate.new
      favorites.stubs(:repost!)

      author = Lotus::Author.new

      @person = Lotus::Person.new
      @person.stubs(:activities).returns(activities)
      @person.stubs(:favorites).returns(favorites)
      @person.stubs(:author).returns(author)
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
        .with(has_entries(:actor_id   => @person.author.id,
                          :actor_type => 'Author'))

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
      activities = Lotus::Aggregate.new
      activities.stubs(:post!)
      favorites = Lotus::Aggregate.new
      favorites.stubs(:delete!)

      author = Lotus::Author.new

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
        .with(has_entries(:actor_id   => @person.author.id,
                          :actor_type => 'Author'))

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

      person.stubs(:mentions).returns(Lotus::Aggregate.new)

      person.mentions.expects(:repost!).with(activity)
      person.mentioned_by! activity
    end
  end

  describe "#replied_by!" do
    it "should repost the activity to our replies aggregate" do
      person = Lotus::Person.new
      activity = Lotus::Activity.new

      person.stubs(:replies).returns(Lotus::Aggregate.new)

      person.replies.expects(:repost!).with(activity)
      person.replied_by! activity
    end
  end

  describe "#post!" do
    it "should post the activity to our activities aggregate" do
      person = Lotus::Person.new
      activity = Lotus::Activity.new

      person.stubs(:timeline).returns(Lotus::Aggregate.new)
      person.stubs(:activities).returns(Lotus::Aggregate.new)

      person.activities.expects(:post!).with(activity)
      person.timeline.stubs(:repost!).with(activity)
      person.post! activity
    end

    it "should repost the activity to our timeline" do
      person = Lotus::Person.new
      activity = Lotus::Activity.new

      person.stubs(:timeline).returns(Lotus::Aggregate.new)
      person.stubs(:activities).returns(Lotus::Aggregate.new)

      person.activities.stubs(:post!).with(activity)
      person.timeline.expects(:repost!).with(activity)
      person.post! activity
    end

    it "should create an activity if passed a hash" do
      activity = Lotus::Activity.new
      person = Lotus::Person.new

      person.stubs(:timeline).returns(Lotus::Aggregate.new)
      person.stubs(:activities).returns(Lotus::Aggregate.new)

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
      @person.stubs(:timeline).returns(Lotus::Aggregate.new)
      @person.stubs(:shared).returns(Lotus::Aggregate.new)
      @person.stubs(:activities).returns(Lotus::Aggregate.new)

      @person.stubs(:author).returns(Lotus::Author.new)

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
        .with(has_entries(:actor_id  => @person.author.id,
                          :actor_type => 'Author'))

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
end

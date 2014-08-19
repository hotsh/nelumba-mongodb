require_relative 'helper'

describe Lotus::Article do
  describe "Schema" do
    it "should have a title" do
      Lotus::Article.keys.keys.must_include "title"
    end

    it "should have a content" do
      Lotus::Article.keys.keys.must_include "content"
    end

    it "should have a uid" do
      Lotus::Article.keys.keys.must_include "uid"
    end

    it "should have a url" do
      Lotus::Article.keys.keys.must_include "url"
    end

    it "should have a display_name" do
      Lotus::Article.keys.keys.must_include "display_name"
    end

    it "should have a summary" do
      Lotus::Article.keys.keys.must_include "summary"
    end

    it "should have an image" do
      Lotus::Article.keys.keys.must_include "image"
    end

    it "should have an author_id" do
      Lotus::Article.keys.keys.must_include "author_id"
    end

    it "should have a published" do
      Lotus::Article.keys.keys.must_include "published"
    end

    it "should have a updated" do
      Lotus::Article.keys.keys.must_include "updated"
    end
  end

  describe "self.find_by_id" do
    it "should not find a different type of object" do
      note = Lotus::Note.new(:content => "foo",
                             :title   => "bar")
      activity = Lotus::Activity.create :object => note

      Lotus::Article.find_by_id(note.id).must_equal nil
    end

    it "should not find by BSON id" do
      article = Lotus::Article.new(:content => "foo",
                                   :title   => "bar")
      activity = Lotus::Activity.create :object => article

      Lotus::Article.find_by_id(article.id).must_equal article
    end

    it "should not find by string id" do
      article = Lotus::Article.new(:content => "foo",
                                   :title   => "bar")
      activity = Lotus::Activity.create :object => article

      Lotus::Article.find_by_id(article.id).must_equal article
    end
  end
end

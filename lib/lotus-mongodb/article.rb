module Lotus
  class Article
    require 'redcarpet'

    include Lotus::EmbeddedObject

    key :markdown

    def initialize(options = {})
      super(options)

      self.render_markdown unless options[:content]
    end

    def markdown=(value)
      super value
      render_markdown
    end

    # Generates content field with the markdown field.
    def render_markdown
      markdown = Redcarpet::Markdown.new(
                   Redcarpet::Render::HTML, :autolink            => true,
                                            :space_after_headers => true)
      self.content = markdown.render(self.markdown)
    end
  end
end

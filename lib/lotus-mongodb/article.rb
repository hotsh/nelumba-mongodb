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
      return if self.markdown.nil?

      render_as = Redcarpet::Render::HTML
      engine = Redcarpet::Markdown.new(render_as, :autolink            => true,
                                                  :space_after_headers => true)
      self.content = engine.render(self.markdown)
    end
  end
end

module Lotus
  class Comment
    include Lotus::EmbeddedObject

    key :in_reply_to, :default => []
  end
end

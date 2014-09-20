module Nelumba
  class Comment
    include Nelumba::EmbeddedObject

    key :in_reply_to, :default => []
  end
end

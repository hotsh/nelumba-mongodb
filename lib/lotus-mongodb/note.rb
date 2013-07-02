module Lotus
  class Note
    include Lotus::EmbeddedObject

    key :text
    key :html
  end
end

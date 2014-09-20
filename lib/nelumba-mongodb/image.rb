module Nelumba
  class Image
    require 'RMagick'

    include Nelumba::EmbeddedObject

    # The array of sizes this image has stored.
    key :sizes, Array, :default => []

    # The content type for the image.
    key :content_type

    # Create a new Image from the given blob
    def self.from_blob!(author, blob, options = {})
      image = self.new({:author_id => author.id}.merge(options))

      canvas = Magick::ImageList.new
      canvas.from_blob(blob)

      self.storage_write "full_image_#{image.id}", blob

      # Store the content_type
      image.content_type = canvas.mime_type

      # Resize the canvass to fit the given sizes (crop to the aspect ratio)
      # And store them in the storage backend.
      options[:sizes] ||= []
      images = options[:sizes].each do |size|
        width  = size[0]
        height = size[1]

        # Resize to maintain aspect ratio
        resized = canvas.resize_to_fill(width, height)
        self.storage_write "image_#{image.id}_#{width}x#{height}", resized.to_blob
      end

      image.url = "/images/#{image.id}"
      image.uid = image.url

      image.save
      image
    end

    # Create a new Avatar from the given url
    def self.from_url!(author, url, options = {})
      # Pull canvas down
      response = self.pull_url(url, options[:content_type])
      return nil unless response.kind_of? Net::HTTPSuccess

      self.from_blob!(author, response.body, options)
    end

    def image(size = nil)
      return nil if self.sizes.empty?

      size = self.sizes.first unless size
      return nil unless self.sizes.include? size

      Nelumba::Image.storage_read "image_#{self.id}_#{size[0]}x#{size[1]}"
    end

    def full_image
      Nelumba::Image.storage_read "full_image_#{self.id}"
    end

    def image_base64(size = nil)
      data = self.image(size)
      return nil unless data

      "data:#{self.content_type};base64,#{Base64.encode64(data)}"
    end

    def full_image_base64
      data = self.full_image
      return nil unless data

      "data:#{self.content_type};base64,#{Base64.encode64(data)}"
    end

    private

    # :nodoc:
    def self.pull_url(url, content_type = nil, limit = 10)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri.request_uri)
      request.content_type = content_type if content_type

      http = Net::HTTP.new(uri.hostname, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      response = http.request(request)

      if response.is_a?(Net::HTTPRedirection) && limit > 0
        location = response['location']
        self.pull_url(location, content_type, limit - 1)
      else
        response
      end
    end

    # :nodoc:
    def self.storage
      @@grid ||= Mongo::Grid.new(MongoMapper.database)
    end

    # TODO: Add ability to read from filesystem
    # :nodoc:
    def self.storage_read(id)
      self.storage.get(id).read
    end

    # TODO: Add ability to store on filesystem
    # :nodoc:
    def self.storage_write(id, data)
      self.storage.put(data, :_id => id)
    end
  end
end

module TransportGateway
  # Representation of a remote resource.  Returned usually from a {ResourceQuery}, such as when listing files on an SFTP endpoint.
  #
  # You should never instantiate this directly.
  class ResourceEntry

    # Name of the resource. Represents the file basename, without path.
    # @return [String]
    attr_reader :name

    # Full URI to this resource.
    # @return [URI]
    attr_reader :uri

    # Resource size.
    attr_reader :size

    # Resource modification time.
    # @return [Integer] - an integer unix timestamp, in UTC
    attr_reader :mtime

    def initialize(name, uri, size, mtime)
      @name = name
      @uri = uri
      @size = size
      @mtime = mtime
    end
  end
end

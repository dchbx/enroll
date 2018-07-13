module TransportGateway
  module Sources
    class FileSource
      attr_reader :stream, :size

      def initialize(path)
        @stream = File.open(path, "rb")
        @size = @stream.size
      end

      def cleanup
        if !@stream.closed?
          @stream.close
        end
      end
    end
  end
end

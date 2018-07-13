module TransportGateway
  module Sources
    class TempfileSource
      attr_reader :stream, :size

      def initialize(stream)
        if stream.closed?
          stream.open
        end
        @size = stream.size
        @stream = stream
        @stream.rewind
      end

      def cleanup
        @stream.close
        @stream.unlink
      end
    end
  end
end

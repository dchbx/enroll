# frozen_string_literal: true

module TransportGateway
  module Sources
    class TempfileSource
      attr_reader :stream, :size

      def initialize(stream)
        stream.open if stream.closed?
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

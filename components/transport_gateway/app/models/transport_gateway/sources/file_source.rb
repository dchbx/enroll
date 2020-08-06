# frozen_string_literal: true

module TransportGateway
  module Sources
    class FileSource
      attr_reader :stream, :size

      def initialize(path)
        @stream = File.open(path, "rb")
        @size = @stream.size
      end

      def cleanup
        @stream.close unless @stream.closed?
      end
    end
  end
end

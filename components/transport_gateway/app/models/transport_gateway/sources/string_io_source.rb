module TransportGateway
  module Sources
    class StringIOSource
      attr_reader :stream, :size
      def initialize(string)
        @size = string.bytesize
        @stream = StringIO.new(string)
      end

      def cleanup
        @stream = nil
      end
    end
  end
end

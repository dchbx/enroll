require "observer"

module TransportGateway
  module Adapters
    module Base
      include Observable 

      attr_reader :gateway, :credential_provider

      def log(level, tag, &blk)
        changed
        notify_observers(level, tag, blk)
      end

      def assign_providers(gw, c_provider)
        @gateway = gw
        @credential_provider = c_provider
      end
    end
  end
end

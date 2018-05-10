module TransportGateway
  class LoggingObserver
    attr_reader :logger

    def initialize(logging_provider)
      @logger = logging_provider
    end

    def update(level, tag, blk)
      logger.send(level.to_sym, tag, &blk)
    end
  end
end

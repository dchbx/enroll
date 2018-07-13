module TransportProfiles
  class Steps::Step
    attr_reader :description

    def initialize(description, gateway)
      @description = description
      @gateway = gateway
    end

    def execute(process_context)
    end
  end
end

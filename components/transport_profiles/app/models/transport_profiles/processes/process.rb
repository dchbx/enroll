module TransportProfiles
  # Base class for all process workflows.
  # 
  # Workflows are implemented by subclassing this and defining an initialize method which invokes super and adds steps.
  #
  # If you would like to start by examining a complicted case, check out {TransportProfiles::Processes::Legacy::TransferPaymentProcessorReports}.
  class Processes::Process

    attr_reader :descriptions, :gateway, :steps

    def initialize(description, gateway)
      @description = description
      @steps = []
      @gateway = gateway
    end

    def add_step(new_step)
      @steps << new_step
    end

    def step_descriptions
      @steps.map { |step| step.description + '\n'  }
    end

    def execute(context = nil)
      context ||= TransportProfiles::ProcessContext.new(self)
      @steps.each do |step|
        begin
          # TODO add logging at start and end of step execution
          step.execute(context)
        rescue => e
          Rails.logger.error { e }
          Rails.logger.error { e.backtrace.join("\n") }
          # TODO add error logging
          # TODO determine if steps should continue when an error is raised
        end
      end
      context.execute_cleanup
    end

    # Define this method in subclasses, it is a list of symbols containing all referenced resources.
    # This is used by a number of rake tasks to diagnose and list endpoints and make sure they are loaded in the database.
    def self.used_endpoints
      raise NotImplementedError.new("subclass responsibility")
    end

    def self.used_context_names
      []
    end
  end
end

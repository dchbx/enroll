module Queries
  class Pipeline
    def initialize(step_list = [])
      @steps = step_list
    end

    def >>(other_expression)
      ::Queries::Pipeline.new(@steps + other_expression.to_pipeline)
    end

    def to_pipeline
      @steps
    end
  end
end

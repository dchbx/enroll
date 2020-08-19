require 'ui_helpers/workflow/step'

module UIHelpers
  module Workflow
    class Steps
      def initialize(steps)
        @steps = steps.map.with_index { |step, number| Workflow::Step.new step['step'], number + 1, self }
      end

      def count
        @steps.count
      end

      def find(step)
        @steps[step - 1]
      end

      def first_step?(step)
        step.to_i == 1
      end

      def last_step?(step)
        @steps.count == step.to_i
      end
    end
  end
end



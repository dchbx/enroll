require 'ui_helpers/workflow/section'

module UIHelpers
  module Workflow
    class Step
      attr_accessor :sections, :heading, :heading_text

      def initialize(step, number, steps)
        @steps = steps
        @heading = step['heading']
        @heading_text = step["heading_text"]
        @sections = step['sections'].map { |section| Workflow::Section.new section["section"] }
        @number = number
      end

      def to_i
        @number
      end

      def next_step
        @steps.find(@number + 1)
      end
    end
  end
end



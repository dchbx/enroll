require 'ui_helpers/workflow/cell'

module UIHelpers
  module Workflow
    class Line
      attr_accessor :cells

      def initialize(line)
        @cells = line['cells'].map { |cell| Workflow::Cell.new cell }
      end
    end
  end
end



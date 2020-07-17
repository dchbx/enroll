require 'ui_helpers/workflow/line'

module UIHelpers
  module Workflow
    class Section
      attr_accessor :heading, :lines, :heading_text, :classNames

      def initialize(section)
        @lines = section["lines"].map { |line| Workflow::Line.new line }
        @heading = section["heading"] if !section['heading'].nil?
        @heading_text = section["heading_text"] if !section['heading_text'].nil?
        @classNames = section["classNames"] if !section['classNames'].nil?
      end
    end
  end
end



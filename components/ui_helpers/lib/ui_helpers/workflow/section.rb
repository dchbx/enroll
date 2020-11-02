# frozen_string_literal: true

require 'ui_helpers/workflow/line'

module UIHelpers
  module Workflow
    class Section
      attr_accessor :heading, :lines, :heading_text, :classNames

      def initialize(section)
        @lines = section["lines"].map { |line| Workflow::Line.new line }
        @heading = section["heading"] unless section['heading'].nil?
        @heading_text = section["heading_text"] unless section['heading_text'].nil?
        @classNames = section["classNames"] unless section['classNames'].nil? # rubocop:disable Naming/VariableName
      end
    end
  end
end



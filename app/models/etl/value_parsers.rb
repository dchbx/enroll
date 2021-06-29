# frozen_string_literal: true

module Etl
  module ValueParsers
    def self.included(base)
      base.class_eval do
        extend(::Etl::ValueParsers::ClassMethods)
        include(::Etl::ValueParsers::ConverterMethods)
      end
    end

    class UnknownParserTypeError < StandardError; end

    module ConverterMethods
      def __parse_gender_value(val)
        return nil if val.blank?

        stripped_value = val.strip.downcase
        case stripped_value
        when /\Am/i
          "male"
        when /\Af/i
          "female"
        else
          val
        end
      end
    end

    module ClassMethods
      CONVERTER_PARSER_LIST = {
        :gender => :__parse_gender_value
      }.freeze

      def attr_converter(*names, as:)
        # Special case until we clean up the module
        if as == :optimistic_ssn
          self.class_eval do
            include ::ValueParsers::OptimisticSsnParser.on(*names)
            attr_reader(*names)
          end
        elsif CONVERTER_PARSER_LIST.include?(as)
          converter_method = CONVERTER_PARSER_LIST[as]
          names.each do |attribute_name|
            self.class_eval(<<-RUBY_CODE)
              def #{attribute_name}=(val)
                @#{attribute_name} = #{converter_method}(val)
              end
              attr_reader :#{attribute_name}
            RUBY_CODE
          end
        else
          raise ::Etl::ValueParsers::UnknownParserTypeError, "#{as} is not a recognized parser"
        end
      end
    end
  end
end

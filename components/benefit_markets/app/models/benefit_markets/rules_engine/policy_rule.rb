module BenefitMarkets
  module RulesEngine
    class PolicyRule
      class RequiredInformationMissingError < ArgumentError
        attr_reader :missing_arguements
        def initialize(err, missing_args = [])
          super(err)
          @missing_arguments = missing_args
        end
      end

      attr_reader :requires
      attr_reader :validate
      attr_reader :success
      attr_reader :failure
      attr_reader :name
      attr_reader :any_of
      attr_reader :all_of
      attr_reader :is_applicable
      attr_reader :is_parent_rule
      attr_reader :child_rules

      NO_OP = lambda {|o| true }

      def initialize(name,
                      requires: [],
                      validate: NO_OP,
                      failure: NO_OP,
                      success: NO_OP,
                      any_of: nil,
                      all_of: nil,
                      applicable_if: NO_OP 
                    )

        @name = name
        @failure = failure
        @success = success
        @is_parent_rule = false
        @is_applicable = applicable_if
        @requires = requires
        if !all_of.blank?
          @all_of = all_of
          @child_rules = all_of
          @is_parent_rule = true
        elsif !any_of.blank?
          @any_of = any_of
          @child_rules = any_of
          @is_parent_rule = true
        else
          @validate = validate
        end
      end

      def evaluate(context)
        missing_keys = @requires - context.provided_values
        if missing_keys.any?
          raise RequiredInformationMissingError.new("required keys missing", missing_keys)
        end
        if !is_applicable.call(context)
          context.set_rule_result(name, :not_applicable)
          return
        end
        if @is_parent_rule
          if !@any_of.blank?
            results = @any_of.map do |r_name|
              context.rule_result(r_name)
            end
            end_result = results.any? { |r| r == true }
            if end_result
              success.call(context)
            else
              failure.call(context)
            end
            context.set_rule_result(self, end_result)
          elsif !@all_of.blank?
            results = @all_of.map do |r_name|
              context.rule_result(r_name)
            end
            end_result = results.all? { |r| r == true }
            if end_result
              success.call(context)
            else
              failure.call(context)
            end
            context.set_rule_result(self, end_result)
          end
        else 
          if validate.call(context)
            success.call(context)
            context.set_rule_result(name, true)
          else
            failure.call(context)
            context.set_rule_result(name, false)
          end
        end
      end
    end
  end
end

module BenefitMarkets
  module RulesEngine
    class PolicyExecutionContext

      def initialize(**kwargs)
        @context_values = {}
        kwargs.each_pair do |k, v|
          @context_values[k.to_sym] = v
        end
        @rule_results = {}
      end

      def set_rules(rules)
        @rules_by_name = {}
        rules.each do |rule|
          @rules_by_name[rule.name] = rule
        end
      end

      def get(kw)
        @context_values[kw]
      end

      def provided_values
        @context_values.keys
      end

      def set_rule_result(name, result)
        @rule_results[name] = result
      end

      def rule_result(name)
        return @rule_results[name] if @rule_results.has_key?(name)
        @rules_by_name[name].evaluate(self)
        @rule_results[name]
      end

      def fail!
        @result = false
      end

      def succeed!
        @result = true
      end

      def failed?
        !@result
      end

      def success?
        !!@result
      end

      def add_error(context, error)
        @context_errors << {context => error}
      end

    end
  end
end

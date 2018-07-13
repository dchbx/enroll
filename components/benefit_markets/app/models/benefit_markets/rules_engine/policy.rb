module BenefitMarkets
  module RulesEngine
    class Policy

      def self.rules
        @rules ||= []
      end

      def self.rule(*args)
        rules
        add_rule(PolicyRule.new(*args))
      end

      def self.add_rule(rule)
        rules << rule
        compile_rules
      end

      def self.rules_to_evaluate
        @rules_to_evaluate ||= []
      end

      def evaluate(context)
        context.set_rules(self.class.rules)
        self.class.rules_to_evaluate.each do |rule|
          rule.evaluate(context)
        end 
      end

      def self.compile_rules
        child_rules = []
        @rules.each do |rule|
          if rule.is_parent_rule
            child_rules = (child_rules + rule.child_rules).uniq
          end
        end
        root_rules = []
        @rules.each do |rule|
          if !child_rules.include?(rule.name)
            root_rules << rule
          end
        end
        @rules_to_evaluate = root_rules
      end
    end
  end
end

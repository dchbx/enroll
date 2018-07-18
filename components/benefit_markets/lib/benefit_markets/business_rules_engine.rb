# A Rules Engine that builds Business Policies comprised of Rules that define criteria to verified
# To use, include it in any class where you want to define:
#   include BenefitMarkets::BusinessRulesEngine
#
# Define Rules:
#   rule  :name_of_first_rule
#         validate: lambda {|o| # do something with o }
#         fail: lambda {|o| o.fail!}}
#         priority: 10,
#
#   rule  :name_of_second_rule
#         validate: lambda {|o| # do something with o }
#         fail: lambda {|o| o.fail!}}
#         priority: 10,
#
# Define Business Policy and associate Rules
#   business_policy :name_of_first_business_policy
#         rules: [:name_of_first_rule, :name_of_second_rule]
#
# Execute the Business Policy:
#   assert_business_policies([:name_of_first_business_policy])
#
module BenefitMarkets
  module BusinessRulesEngine
    extend ActiveSupport::Concern

    included do
      class_attribute :business_policies
      class_attribute :rules
      self.business_policies = {}
      self.rules = []
    end

    module ClassMethods
      def assert_business_policies(names = [])
        if names.size == 0
          business_policies.each do |business_policy_name, business_policy|
            business_policy.send(:process_rules)
          end
        else
          business_policies[name].send(:process_rules) if business_policies.has_key?(name)
        end
      end

      def register_business_policy(name, business_policy)
        raise Error, "business_policy #{name} already exists" if business_policies.has_key?(name)
        business_policies[name] = business_policy
        business_policy
      end

      def business_policy(name, options={})
        if options[:rules].present? and options[:rules].size > 0
          options[:rules] = options[:rules].reduce([]) do |list, rule|
            if rule.is_a? BusinessRulesEngine::Rule
              list << rule
            else
              rule_instance = find_rule_by_name(rule)

              if rule_instance.present?
                list << rule_instance
              else
                raise Error, "rule not found: #{rule}"
              end
            end

            list
          end
        end

        business_policy = BusinessRulesEngine::BusinessPolicy.new(name, options)
        register_business_policy(name, business_policy)
      end

      def business_policies
        self.business_policies ||= {}
      end

      # def [](name)
      #   business_policies[name] if business_policies.has_key?(name)
      # end

      def rule(name, options={})
        rule_instance = BusinessRulesEngine::Rule.new(name, options)
        self.rules << rule_instance
        rule_instance
      end

      def rules
        self.rules || []
      end

      def find_rule_by_name(name)
        self.rules.detect { |rule| name == rule.name }
      end

      def reset_rules
        self.rules = []
      end

      def reset_business_policies
        self.business_policies = {}
      end
    end

    class BusinessPolicy

      attr_accessor :name
      attr_accessor :fail_results, :success_results

      def initialize(name, options={})
        @name = name
        @rules = options[:rules] || []
        @fail_results = {}
        @success_results = {}
      end

      def is_satisfied?(model_instance)
        reset_results
        process_rules(model_instance)

        begin
            File.open("business_rules_engine_errors.txt", "a+") { |f|
            f << "\n---------" + "\n"
            f << Time.now.getutc.to_s + "\n"
            f << model_instance.class.to_s + "\n"
            f << model_instance.id.to_s + "\n"
            f << "Current state: #{model_instance.aasm_state}" + "\n"
            f << "Non Biz Owner Count: " + model_instance.try(:enrolled_non_business_owner_count).try(:to_s) + "\n"
            f << "Members Eligible to Enroll: " + model_instance.try(:members_eligible_to_enroll_count).try(:to_s) + "\n"
            f << "Ratio: #{model_instance.enrollment_ratio}\n"
            f << @fail_results.to_s + "\n"
            f << @success_results.to_s + "\n"
            f << model_instance.try(:benefit_sponsorship).try(:organization).try(:legal_name) + "\n"
            f << "---------" + "\n\n"
          }
        rescue

        end

        @fail_results.empty?
      end

      def process_rules(model_instance)
        rules.sort_by(&:priority).each do |rule|
          success, result = rule.run(model_instance)
          if success
            @success_results[rule.name] = result
          else
            @fail_results[rule.name] = result
          end
        end
      end

      def <<(new_rule)
        if new_rule.is_a? BusinessRulesEngine::Rule
          @rules << new_rule
          new_rule
        else
         raise Error, "must be type: BusinessRulesEngine::Rule"
        end
      end

      def [](id)
        @rules[id]
      end

      def []=(index, rule)
        @rules[index] = rule
      end

      def add_rule(new_rule)
        @rules << new_rule
      end

      def drop_rule(rule, &blk)
        @rules.delete(rule)
      end

      def errors
        @errors || []
      end

      def reset_errors
        @errors = []
      end

      def rules
        @rules || []
      end

      def reset_rules
        @rules = []
        reset_errors
      end

      def reset_results
        @success_results = {}
        @fail_results = {}
      end

      def inspect
        "<#{self.class.name} name: #{name}, rules: #{rules.each {|rule| rule.inspect} }, errors: #{errors} >"
      end

    end

    class Rule
      attr_accessor :name, :priority

      # hash with values to be evaluated
      attr_accessor :params

      # proc to test
      attr_accessor :validate

      # if valid
      attr_accessor :success

      # if invalid
      attr_accessor :fail

      NO_OP = lambda { |o| true }

      def initialize(name = nil, options={})
        self.name(name) if name.present?
        self.params   = options[:params]    || {}
        self.validate = options[:validate]  || NO_OP
        self.success  = options[:success]   || NO_OP
        self.fail     = options[:fail]      || NO_OP
        self.priority = options[:priority]  || 10
      end

      def name(name = nil)
        @name = name if (name && ! @name)
        @name if defined?(@name)
      end

      def run(data)
        if validate.call(data)
          [true, success.call(data)]
        else
          [false, fail.call(data)]
        end
      end

      def inspect
        "<#{self.class.name} name: #{name}, priority: #{self.priority}, params: #{self.params}, validate: #{self.validate}, success: #{self.success}, fail: #{self.fail} >"
      end

    end
  end
end

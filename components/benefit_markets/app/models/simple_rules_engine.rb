module SimpleRulesEngine
  extend ActiveSupport::Concern

  included do
    class_attribute :rules
    self.rules = []

    delegate :rule, to: :class

    def process_rules(collection)
      collection.each do |row|
        rules.sort_by(&:priority).each do |rule|
          rule.run(row)
        end
      end
    end
  end

  class_methods do

    def rule(name,options={})
      self.rules << SimpleRulesEngine::Rule.new(name,options)
    end
  end


  ## Helper Classes
  class Rule
    attr_accessor :priority
    attr_accessor :name

    # proc to test
    attr_accessor :validate

    # if valid
    attr_accessor :success

    # if invalid
    attr_accessor :fail

    # test output
    attr_accessor :output

    NO_OP = lambda {|o| true }

    def initialize(name, options={})
      self.name = name
      self.priority = options[:priority] || 10
      self.validate = options[:validate] || NO_OP
      self.fail = options[:fail] || NO_OP
      self.success = options[:success] || NO_OP

      @output = nil
    end

    def run(data)
      if @output = validate.call(data)
        success.call(data)
      else
        fail.call(data)
      end

    end
  end
end

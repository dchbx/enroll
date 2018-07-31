# /lib/simple_rules_engine
# To use, just include it in any file where you need some rules engine love ...
# then defile rules like so:
#
# rule :name_of_rule,
#       priority: 10,
#       validate: lambda {|o| # do something with o}
#       fail: lambda {|o| o.fail!}} 
# 
# then to run the engine
# process_rules(your_data_set)
#   
module SimpleRulesEngine
  extend ActiveSupport::Concern

  included do
    class_attribute :rules
    self.rules = []
  end

  module ClassMethods

    # rule :name_of_rule,
    #       priority: 10,
    #       validate: lambda {|o| # do something with o}
    #       fail: lambda {|o| o.fail!}}
    def rule(name,options={})
      self.rules << SimpleRulesEngine::Rule.new(name,options)
    end

    def process_rules(collection)
      collection.each do |row|
        rules.sort_by(&:priority).each do |rule|
          rule.run(row)
        end
        row.valid!
      end
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

    NO_OP = lambda {|o| true }

    def initialize(name, options={})
      self.name = name
      self.priority = options[:priority] || 10
      self.validate = options[:validate] || NO_OP
      self.fail = options[:fail] || NO_OP
      self.success = options[:success] || NO_OP
    end

    def run(data)

      if validate.call(data)
        success.call(data)
      else
        fail.call(data)
      end

    end
  end

end
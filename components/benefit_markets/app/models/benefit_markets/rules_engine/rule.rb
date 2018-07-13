module BenefitMarkets
  class RulesEngine::Rule

    attr_accessor :name, :priority

    # proc to test
    attr_accessor :validate

    # if valid
    attr_accessor :success

    # if invalid
    attr_accessor :fail

    NO_OP = lambda {|o| true }

    def initialize(name, options={})
      @name     = name
      @priority = options[:priority]  || 10
      @validate = options[:validate]  || NO_OP
      @fail     = options[:fail]      || NO_OP
      @success  = options[:success]   || NO_OP
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

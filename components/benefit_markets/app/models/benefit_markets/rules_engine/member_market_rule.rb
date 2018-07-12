module BenefitMarkets
  class RulesEngine::MemberMarketRule
    include SimpleRulesEngine

    rule :child_age_off_policy,
           validate: lambda {|v,fact| v.child_age_off_policy == fact.age_on(Date.today) },
           success: lambda {|v,fact| puts "is of child age" },
           fail: lambda {|v,fact| puts "is not of child age"}


    rule :age_range_policy,
          validate: lambda {|v,fact| v.age_range_policy.member?(fact.age_on(Date.today)) },
          success: lambda {|v,fact| puts "within range" },
          fail: lambda {|v,fact| puts "not within range"}

    attr_accessor :object
    attr_accessor :policy

    # Accepts an object and a policy
    def initialize(object,policy=nil)
      @object = object
      @policy = policy
    end

  end
end

# frozen_string_literal: true

module BenefitMarkets
  class RulesEngine::MemberMarketRule
    include SimpleRulesEngine

    # Date.today converted to TimeKeeper
    rule(
      :child_age_off_policy,
      validate: ->(v, fact) { v.child_age_off_policy == fact.age_on(TimeKeeper.date_of_record) },
      success: ->(_v, _fact) { puts "is of child age" },
      fail: ->(_v,_fact) { puts "is not of child age"}
    )

    rule(
      :age_range_policy,
      validate: ->(v,fact) { v.age_range_policy.member?(fact.age_on(TimeKeeper.date_of_record)) },
      success: ->(_v,_fact) { puts "within range" },
      fail: ->(_v,_fact) { puts "not within range" }
    )

    attr_accessor :object
    attr_accessor :policy

    # Accepts an object and a policy
    def initialize(object,policy = nil)
      @object = object
      @policy = policy
    end

  end
end

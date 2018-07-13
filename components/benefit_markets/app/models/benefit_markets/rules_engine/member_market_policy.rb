module BenefitMarkets
  class RulesEngine::MemberMarketPolicy
    #include BenefitMarkets::RulesEngine::Policy


    # We can define policies as a macro inside class similar to Mongoid 'field'
    #policy(:enrollment_group) do
    #  rule :child_age_off_policy,
    #        validate: lambda {|v, fact| v.child_age_off_policy == fact.age_on(Date.today) },
    #        success:  lambda {|v, fact| puts "is of child age" },
    #        fail:     lambda {|v, fact| puts "is not of child age"}
    #
    #  rule :age_range_policy,
    #        validate: lambda {|v, fact| v.age_range_policy.member?(fact.age_on(Date.today)) },
    #        success:  lambda {|v, fact| puts "within range" },
    #        fail:     lambda {|v, fact| puts "not within range"}
    #end




    #policy(:enrollment_group).rules           # => [<RulesEngine::Rule child_age_off_policy>, ,RulesEngine::Rule age_range_policy>]
    #policy_satisfied? = policy(:enrollment_group).process_rules   # executes rules that returns boolean result
    #object = policy(:enrollment_group).process_rules   # executes rules that returns object result

  end
end

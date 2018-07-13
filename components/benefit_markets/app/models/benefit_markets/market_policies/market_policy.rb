module BenefitMarkets
  class MarketPolicies::MarketPolicy
    include Mongoid::Document
    include Mongoid::Timestamps

    policy = {
                title: "age_range_policy",
                criteria: "",
                
    }



      maps = [ 
        composite_rating: { 
          employee_only: {
            title: "Employee Only", 
            visible: true,
            ordinal_position: 1,

            eligibility_criteria: {
              member_count: 1..1,
              relationships_excluded: [:child_under_26, :child_26_and_over, :disabled_child_26_and_over],
              composition: {
                  members: [
                    {
                      relationships_included: [:employee],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                  ]
              }, # composition
            }, # eligibility_criteria
          }, # employee_only

          employee_and_spouse: {
            title: "Employee and Spouse", 
            visible: true,
            ordinal_position: 2,
            eligibility_criteria: {
              member_count: 2..2,
              relationships_excluded: [:child_under_26, :child_26_and_over, :disabled_child_26_and_over],
              composition: {
                  members: [
                    {
                      relationships_included: [:employee],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                    {
                      relationships_included: [:spouse, :domestic_partner],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },       
                  ]
              }, # composition
            }, # eligibility criteria
          }, #employee and spouse

          employee_and_one_or_more_dependents: {
            title: "Employee and One or More Dependents", 
            visible: true,
            ordinal_position: 3,
            eligibility_criteria: {
              member_count: 2..20,
              relationships_excluded: [:spouse, :domestic_partner],
              composition: {
                  members: [
                    {
                      relationships_included: [:employee],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                    {
                      relationships_included: [:spouse],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                  ]
              }, # composition
            }, # eligibility criteria
          }, # employee_and_one_or_more_dependents


          family: {
            title: "Family", 
            visible: true,
            ordinal_position: 4,
            eligibility_criteria: {
              member_count: 3..20,
              relationships_excluded: [],
              composition: {
                  members: [
                    {
                      relationships_included: [:employee],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },
                    {
                      relationships_included: [:spouse, :domestic_partner],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },    
                    {
                      relationships_included: [:child_under_26, :child_26_and_over, :disabled_child_26_and_over],
                      age:                    0..0,
                      age_on_effective_date:  0..0,
                      disabled:               :any,
                      alive:                  true,
                      employment_state:       :any,
                    },    
                  ]
              }, # composition
            }, # eligibility criteria
          }, # family

        }, # composite rating


        choice_rating: { 

        }, # choice rating

      ]


  end
end

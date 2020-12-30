FactoryBot.define do
  factory :benefit_markets_contribution_models_fixed_percent_contribution_unit, class: 'BenefitMarkets::ContributionModels::FixedPercentContributionUnit' do

    transient do
      member_relationship_operator { :>= }
    end

    trait :with_member_relationship_maps do
      member_relationship_maps {
      	[ 
      		build(:benefit_markets_contribution_models_member_relationship_map,
            relationship_name: name,
            operator: member_relationship_operator,
            contribution_unit: self,
            count: 1)
      	]
      }
    end
  end
end

FactoryBot.define do
  factory :benefit_markets_contribution_models_contribution_model, class: 'BenefitMarkets::ContributionModels::ContributionModel' do

    sponsor_contribution_kind { "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution" }
    contribution_calculator_kind  { "::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator" }
    title  { "#{Settings.site.key.to_s.upcase} Shop Simple List Bill Contribution Model" }
    key { :zero_percent_sponsor_fixed_percent_contribution_model }
    many_simultaneous_contribution_units { true }

    after(:build) do |contribution_model|

      contribution_model.member_relationships = [
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: "employee",
          relationship_kinds: ["self"]
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: "spouse",
          relationship_kinds: ["spouse"]
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: "domestic_partner",
          relationship_kinds: ["life_partner", "domestic_partner"]
        ),
        BenefitMarkets::ContributionModels::MemberRelationship.new(
          relationship_name: "dependent",
          relationship_kinds: ["child", "adopted_child", "foster_child", "stepchild", "ward"]
        )
      ]

      employee_unit = build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
                            name: "employee",
                            display_name: "Employee",
                            order: 0,
                            default_contribution_factor: 0.75,
                            contribution_model: contribution_model)

      build(:benefit_markets_contribution_models_member_relationship_map,
            relationship_name: "employee",
            operator: :==,
            count: 1,
            contribution_unit: employee_unit
            )

      spouse_unit = build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
                          name: "spouse",
                          display_name: "Spouse",
                          order: 1,
                          default_contribution_factor: 0.50,
                          contribution_model: contribution_model)

      build(:benefit_markets_contribution_models_member_relationship_map,
            relationship_name: "spouse",
            operator: :>=,
            contribution_unit: spouse_unit,
            count: 1)

      dm_partner_unit =  build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
                               name: "domestic_partner",
                               display_name: "Domestic Partner",
                               order: 2,
                               default_contribution_factor: 0.25,
                               contribution_model: contribution_model)

      build(:benefit_markets_contribution_models_member_relationship_map,
            relationship_name: "domestic_partner",
            operator: :>=,
            contribution_unit: dm_partner_unit,
            count: 1
            )

      dependent_unit = build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
                             name: "dependent",
                             display_name: "Child Under 26",
                             order: 3,
                             default_contribution_factor: 0.25,
                             contribution_model: contribution_model)

      build(:benefit_markets_contribution_models_member_relationship_map,
            relationship_name: "dependent",
            operator: :>=,
            contribution_unit: dependent_unit,
            count: 1
            )
    end

    trait :for_health_single_product do
      # toDo
    end
  end
end

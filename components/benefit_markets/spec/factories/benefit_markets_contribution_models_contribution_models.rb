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

      contribution_factor = contribution_model.key == :zero_percent_sponsor_fixed_percent_contribution_model ? 0.0 : 0.5

      contribution_model.contribution_units = [
        build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
              :with_member_relationship_maps,
              name: "employee",
              display_name: "Employee",
              order: 0,
              default_contribution_factor: contribution_factor,
              minimum_contribution_factor: contribution_factor,
              member_relationship_operator: :==),
        build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
              :with_member_relationship_maps,
              name: "spouse",
              display_name: "Spouse",
              order: 1,
              default_contribution_factor: 0.0,
              minimum_contribution_factor: 0.0),
        build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
              :with_member_relationship_maps,
              name: "domestic_partner",
              display_name: "Domestic Partner",
              order: 2,
              default_contribution_factor: 0.0,
              minimum_contribution_factor: 0.0),
        build(:benefit_markets_contribution_models_fixed_percent_contribution_unit,
              :with_member_relationship_maps,
              name: "dependent",
              display_name: "Child Under 26",
              order: 3,
              default_contribution_factor: 0.0,
              minimum_contribution_factor: 0.0)
      ]
    end

    trait :for_health_single_product do
      # toDo
    end
  end
end

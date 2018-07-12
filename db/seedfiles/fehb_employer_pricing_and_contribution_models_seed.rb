employer_pricing_units = [
  BenefitMarkets::PricingModels::RelationshipPricingUnit.new(
    name: "employee",
    display_name: "employee",
    order: 0
  ),
  BenefitMarkets::PricingModels::RelationshipPricingUnit.new(
    name: "spouse",
    display_name: "spouse",
    order: 1
  ),
  BenefitMarkets::PricingModels::RelationshipPricingUnit.new(
    name: "dependent",
    display_name: "dependent",
    order: 2,
    discounted_above_threshold: 4,
    eligible_for_threshold_discount: true
  )
]

employer_member_relationships = [
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "employee",
    relationship_kinds: ["self"]
  ),
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "spouse",
    relationship_kinds: ["spouse", "life_partner"]
  ),
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 27,
    age_comparison: :<,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"]
  ),
  BenefitMarkets::PricingModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 27,
    age_comparison: :>=,
    disability_qualifier: true,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"]
  )

]

pricing_model = BenefitMarkets::PricingModels::PricingModel.create!(
  :price_calculator_kind => "::BenefitSponsors::PricingCalculators::ShopSimpleListBillPricingCalculator",
  :pricing_units => employer_pricing_units,
  :member_relationships => employer_member_relationships,
  :name => "FEHB Employer Price Model"
)

employer_contribution_relationships = [
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "employee",
    relationship_kinds: ["self"]
  ),
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "dependent",
    relationship_kinds: ["spouse", "life_partner"]),
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 27,
    age_comparison: :<,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"]),
  BenefitMarkets::ContributionModels::MemberRelationship.new(
    relationship_name: "dependent",
    age_threshold: 27,
    age_comparison: :>=,
    disability_qualifier: true,
    relationship_kinds: ["child", "adopted_child","foster_child","stepchild", "ward"])
]

employer_contribution_units = [
  BenefitMarkets::ContributionModels::PercentWithCapContributionUnit.new(
    name: "employee",
    display_name: "Employee",
    order: 0,
    default_contribution_factor: 0.75,
    default_contribution_cap: 496.71,
    member_relationship_maps: [
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "employee",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :==,
        count: 0 
      })
    ]
  ),
  BenefitMarkets::ContributionModels::PercentWithCapContributionUnit.new(
    name: "employee_plus_1",
    display_name: "Employee + 1",
    order: 1,
    default_contribution_factor: 0.75,
    default_contribution_cap: 1063.83,
    member_relationship_maps: [
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "employee",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :==,
        count: 1
      })
    ]
  ),
  BenefitMarkets::ContributionModels::PercentWithCapContributionUnit.new(
    name: "employee_plus_2_or_more",
    display_name: "Employee + 2 or more",
    order: 2,
    default_contribution_factor: 0.75,
    default_contribution_cap: 1130.09,
    member_relationship_maps: [
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "employee",
        operator: :==,
        count: 1
      }),
      BenefitMarkets::ContributionModels::MemberRelationshipMap.new({
        relationship_name: "dependent",
        operator: :>=,
        count: 2
      })
    ]
  )
]

# Contribution Models
contribution_model = BenefitMarkets::ContributionModels::ContributionModel.create!({
  sponsor_contribution_kind: "::BenefitSponsors::SponsoredBenefits::FixedPercentWithCapSponsorContribution",
  contribution_calculator_kind: "::BenefitSponsors::ContributionCalculators::TieredPercentWithCapContributionCalculator",
  contribution_units: employer_contribution_units,
  member_relationships: employer_contribution_relationships,
  name: "FEHB Employer Contribution Model"
})

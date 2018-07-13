FactoryGirl.define do
  factory :benefit_markets_pricing_models_pricing_model, class: 'BenefitMarkets::PricingModels::PricingModel' do

    price_calculator_kind "::BenefitSponsors::PricingCalculators::ShopSimpleListBillPricingCalculator"
    name  "FEHB Employer Price Model"

    after(:build) do |pricing_model|

      pricing_model.member_relationships = [

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

      pricing_model.pricing_units = [

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

    end
  end
end
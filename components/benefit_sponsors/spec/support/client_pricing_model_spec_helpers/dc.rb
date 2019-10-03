module BenefitSponsors
  module ClientPricingModelSpecHelpers
    module DC
    def list_bill_pricing_model
      {"_id"=>BSON::ObjectId.new,
        "product_multiplicities"=>["multiple", "single"],
        "price_calculator_kind"=>
         "::BenefitSponsors::PricingCalculators::ShopSimpleListBillPricingCalculator",
        "name"=>"DC List Bill Shop Pricing Model",
        "member_relationships"=>
         [{"_id"=>BSON::ObjectId.new,
           "relationship_name"=>:employee,
           "relationship_kinds"=>["self"]},
          {"_id"=>BSON::ObjectId.new,
           "relationship_name"=>:spouse,
           "relationship_kinds"=>["spouse", "life_partner", "domestic_partner"]},
          {"_id"=>BSON::ObjectId.new,
           "relationship_name"=>:dependent,
           "age_threshold"=>26,
           "age_comparison"=>:<,
           "relationship_kinds"=>
            ["child", "adopted_child", "foster_child", "stepchild", "ward"]},
          {"_id"=>BSON::ObjectId.new,
           "relationship_name"=>:dependent,
           "age_threshold"=>26,
           "age_comparison"=>:>=,
           "disability_qualifier"=>true,
           "relationship_kinds"=>
            ["child", "adopted_child", "foster_child", "stepchild", "ward"]}],
        "pricing_units"=>
         [{"_id"=>BSON::ObjectId.new,
           "_type"=>"BenefitMarkets::PricingModels::RelationshipPricingUnit",
           "name"=>"employee",
           "display_name"=>"Employee",
           "order"=>0,
           "eligible_for_threshold_discount"=>false},
          {"_id"=>BSON::ObjectId.new,
           "_type"=>"BenefitMarkets::PricingModels::RelationshipPricingUnit",
           "name"=>"spouse",
           "display_name"=>"Spouse",
           "order"=>1,
           "eligible_for_threshold_discount"=>false},
          {"_id"=>BSON::ObjectId.new,
           "_type"=>"BenefitMarkets::PricingModels::RelationshipPricingUnit",
           "name"=>"dependent",
           "display_name"=>"Dependents",
           "order"=>2,
           "discounted_above_threshold"=>4,
           "eligible_for_threshold_discount"=>true}]}
    end
  end
  end
end
module BenefitSponsors
  module ClientPricingModelSpecHelpers
    module CCA
    def list_bill_pricing_model
      {"_id"=>BSON::ObjectId.new,
        "product_multiplicities"=>["multiple", "single"],
        "price_calculator_kind"=>
         "::BenefitSponsors::PricingCalculators::CcaShopListBillPricingCalculator",
        "name"=>"MA List Bill Shop Pricing Model",
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

    def composite_pricing_model
      pricing_model_id = BSON::ObjectId.new
      {
        "_id": BSON::ObjectId.new,
        product_multiplicities: [ 
            "single"
        ],
        price_calculator_kind: "::BenefitSponsors::PricingCalculators::CcaCompositeTieredPriceCalculator",
        name: "MA Composite Price Model",
        member_relationships: [
          {"_id"=>BSON::ObjectId.new,
            "relationship_name"=>:employee,
            "relationship_kinds"=>["self"]},
           {"_id"=>"5b044e499f880b5d6f36c76a",
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
             ["child", "adopted_child", "foster_child", "stepchild", "ward"]}
        ],
        pricing_units: [
          {"_id"=>BSON::ObjectId.new,
          "_type"=>"BenefitMarkets::PricingModels::TieredPricingUnit",
          "name"=>"employee_only",
          "display_name"=>"Employee Only",
          "order"=>0,
          "member_relationship_maps"=>
           [{"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:employee,
             "count"=>1},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:spouse,
             "count"=>0},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:dependent,
             "count"=>0}]},
         {"_id"=>BSON::ObjectId.new,
          "_type"=>"BenefitMarkets::PricingModels::TieredPricingUnit",
          "name"=>"employee_and_spouse",
          "display_name"=>"Employee and Spouse",
          "order"=>1,
          "member_relationship_maps"=>
           [{"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:employee,
             "count"=>1},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:spouse,
             "count"=>1},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:dependent,
             "count"=>0}]},
         {"_id"=>BSON::ObjectId.new,
          "_type"=>"BenefitMarkets::PricingModels::TieredPricingUnit",
          "name"=>"employee_and_one_or_more_dependents",
          "display_name"=>"Employee and Dependents",
          "order"=>2,
          "member_relationship_maps"=>
           [{"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:employee,
             "count"=>1},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:spouse,
             "count"=>0},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:>=,
             "relationship_name"=>:dependent,
             "count"=>1}]},
         {"_id"=>BSON::ObjectId.new,
          "_type"=>"BenefitMarkets::PricingModels::TieredPricingUnit",
          "name"=>"family",
          "display_name"=>"Family",
          "order"=>3,
          "member_relationship_maps"=>
           [{"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:employee,
             "count"=>1},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:spouse,
             "count"=>1},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:>=,
             "relationship_name"=>:dependent,
             "count"=>1}]}
            ]
      }
    end
  end
  end
end
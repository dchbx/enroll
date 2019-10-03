module BenefitSponsors
  module ClientContributionModelSpecHelpers
    module CCA
    def list_bill_contribution_model
      {"_id"=>BSON::ObjectId.new,
        "product_multiplicities"=>["multiple", "single"],
        "sponsor_contribution_kind"=>
         "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution",
        "contribution_calculator_kind"=>
         "::BenefitSponsors::ContributionCalculators::CcaShopReferencePlanContributionCalculator",
        "title"=>"MA List Bill Shop Contribution Model",
        "many_simultaneous_contribution_units"=>true,
        "contribution_units"=>
         [{"_id"=>BSON::ObjectId.new,
           "_type"=>
            "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
           "minimum_contribution_factor"=>0.5,
           "name"=>"employee",
           "display_name"=>"Employee",
           "order"=>0,
           "default_contribution_factor"=>0.0,
           "member_relationship_maps"=>
            [{"_id"=>BSON::ObjectId.new,
              "operator"=>:==,
              "relationship_name"=>:employee,
              "count"=>1}]},
          {"_id"=>BSON::ObjectId.new,
           "_type"=>
            "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
           "minimum_contribution_factor"=>0.33,
           "name"=>"spouse",
           "display_name"=>"Spouse",
           "order"=>1,
           "default_contribution_factor"=>0.0,
           "member_relationship_maps"=>
            [{"_id"=>BSON::ObjectId.new,
              "operator"=>:>=,
              "relationship_name"=>:spouse,
              "count"=>1}]},
          {"_id"=>BSON::ObjectId.new,
           "_type"=>
            "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
           "minimum_contribution_factor"=>0.33,
           "name"=>"domestic_partner",
           "display_name"=>"Domestic Partner",
           "order"=>2,
           "default_contribution_factor"=>0.0,
           "member_relationship_maps"=>
            [{"_id"=>BSON::ObjectId.new,
              "operator"=>:>=,
              "relationship_name"=>:domestic_partner,
              "count"=>1}]},
          {"_id"=>BSON::ObjectId.new,
           "_type"=>
            "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
           "minimum_contribution_factor"=>0.33,
           "name"=>"dependent",
           "display_name"=>"Child Under 26",
           "order"=>3,
           "default_contribution_factor"=>0.0,
           "member_relationship_maps"=>
            [{"_id"=>BSON::ObjectId.new,
              "operator"=>:>=,
              "relationship_name"=>:dependent,
              "count"=>1}]}],
        "member_relationships"=>
         [{"_id"=>BSON::ObjectId.new,
           "relationship_name"=>:employee,
           "relationship_kinds"=>["self"]},
          {"_id"=>"5b044e499f880b5d6f36c798",
           "relationship_name"=>:spouse,
           "relationship_kinds"=>["spouse"]},
          {"_id"=>BSON::ObjectId.new,
           "relationship_name"=>:domestic_partner,
           "relationship_kinds"=>["life_partner", "domestic_partner"]},
          {"_id"=>BSON::ObjectId.new,
           "relationship_name"=>:dependent,
           "relationship_kinds"=>
            ["child", "adopted_child", "foster_child", "stepchild", "ward"]}]}
    end

    def composite_contribution_model
      contribution_model_id = BSON::ObjectId.new
      {
        "_id": contribution_model_id,
        product_multiplicities: [ 
          "single"
        ],
        sponsor_contribution_kind: "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution",
        contribution_calculator_kind: "::BenefitSponsors::ContributionCalculators::TieredPercentContributionCalculator",
        title: "MA Composite Contribution Model",
        many_simultaneous_contribution_units: false,
        contribution_units: [
          {
          "_id"=>BSON::ObjectId.new,
          "_type"=>"BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
          "minimum_contribution_factor"=>0.5,
          "name"=>"employee_only",
          "display_name"=>"Employee Only",
          "order"=>0,
          "default_contribution_factor"=>0.0,
          "member_relationship_maps"=>
           [{"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:employee,
             "count"=>1},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:dependent,
             "count"=>0}]},
         {"_id"=>BSON::ObjectId.new,
          "_type"=>"BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
          "minimum_contribution_factor"=>0.33,
          "name"=>"family",
          "display_name"=>"Family",
          "order"=>1,
          "default_contribution_factor"=>0.0,
          "member_relationship_maps"=>
           [{"_id"=>BSON::ObjectId.new,
             "operator"=>:==,
             "relationship_name"=>:employee,
             "count"=>1},
            {"_id"=>BSON::ObjectId.new,
             "operator"=>:>=,
             "relationship_name"=>:dependent,
             "count"=>1}]}
        ],
        member_relationships: [
          {"_id"=>BSON::ObjectId.new,
          "relationship_name"=>:employee,
          "relationship_kinds"=>["self"]},
         {"_id"=>BSON::ObjectId.new,
          "relationship_name"=>:dependent,
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
          ]
      }
    end
  end
  end
end
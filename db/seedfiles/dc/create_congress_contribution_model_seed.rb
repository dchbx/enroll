c_model_attributes = {
    product_multiplicities: [
        "single",
        "multiple"
    ],
    sponsor_contribution_kind: "::BenefitSponsors::SponsoredBenefits::FixedPercentWithCapSponsorContribution",
    contribution_calculator_kind: "::BenefitSponsors::ContributionCalculators::TieredPercentWithCapContributionCalculator",
    title: "DC Congress Contribution Model",
    many_simultaneous_contribution_units: false,
    updated_at: Date.today,
    created_at: Date.today,
    contribution_units: [
        {
            "_id"=>BSON::ObjectId.new,
            "_type"=>"BenefitMarkets::ContributionModels::PercentWithCapContributionUnit",
            "minimum_contribution_factor"=>0.5,
            "name"=>"employee_only",
            "display_name"=>"Employee Only",
            "order"=>0,
            "default_contribution_factor"=>0.0,
            "default_contribution_cap" => 0.0,
            "member_relationship_maps"=>
                [{"_id"=>BSON::ObjectId.new,
                  "operator"=>:==,
                  "relationship_name"=>:employee,
                  "count"=>1},
                 {"_id"=>BSON::ObjectId.new,
                  "operator"=>:==,
                  "relationship_name"=>:dependent,
                  "count"=>0}]
        },
        {
            "_id"=>BSON::ObjectId.new,
            "_type"=>"BenefitMarkets::ContributionModels::PercentWithCapContributionUnit",
            "minimum_contribution_factor"=>0.5,
            "name"=>"employee_plus_one",
            "display_name"=>"Employee + 1",
            "order"=>0,
            "default_contribution_factor"=>0.0,
            "default_contribution_cap" => 0.0,
            "member_relationship_maps"=>
                [{"_id"=>BSON::ObjectId.new,
                  "operator"=>:==,
                  "relationship_name"=>:employee,
                  "count"=>1},
                 {"_id"=>BSON::ObjectId.new,
                  "operator"=>:==,
                  "relationship_name"=>:dependent,
                  "count"=>1}]
        },
        {
            "_id"=>BSON::ObjectId.new,
            "_type"=>"BenefitMarkets::ContributionModels::PercentWithCapContributionUnit",
            "minimum_contribution_factor"=>0.33,
            "name"=>"family",
            "display_name"=>"Family",
            "order"=>1,
            "default_contribution_factor"=>0.0,
            "default_contribution_cap" => 0.0,
            "member_relationship_maps"=>
                [{"_id"=>BSON::ObjectId.new,
                  "operator"=>:==,
                  "relationship_name"=>:employee,
                  "count"=>1},
                 {"_id"=>BSON::ObjectId.new,
                  "operator"=>:>,
                  "relationship_name"=>:dependent,
                  "count"=>1}]
        }
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

BenefitMarkets::ContributionModels::ContributionModel.collection.insert_one(c_model_attributes)
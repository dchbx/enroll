module BenefitSponsors
  module ClientContributionModelSpecHelpers
    module DC
      def list_bill_contribution_model
        fifty_percent_contribution_model
      end

      def zero_percent_contribution_model
        title = 'Zero Percent Sponsor Fixed Percent Contribution Model'
        {
          "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9df'),
          "product_multiplicities" => ["multiple", "single"],
          "sponsor_contribution_kind" => "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution",
          "contribution_calculator_kind" => "::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator",
          "title" => title,
          "key" => title.downcase.gsub(/\s/, '_'),
          "many_simultaneous_contribution_units" => true,
          "contribution_units" =>
          [
            {
              "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e0'),
              "_type" =>
              "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => 0.0,
              "name" => "employee",
              "display_name" => "Employee",
              "order" => 0,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e1'),
                  "operator" => :==,
                  "relationship_name" => :employee,
                  "count" => 1
                }
              ]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e2'),
              "_type" =>
               "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => 0.0,
              "name" => "spouse",
              "display_name" => "Spouse",
              "order" => 1,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e3'),
                  "operator" => :>=,
                  "relationship_name" => :spouse,
                  "count" => 1
                }
              ]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e4'),
              "_type" =>
              "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => 0.0,
              "name" => "domestic_partner",
              "display_name" => "Domestic Partner",
              "order" => 2,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e5'),
                  "operator" => :>=,
                  "relationship_name" => :domestic_partner,
                  "count" => 1
                }
              ]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e6'),
              "_type" =>
              "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => 0.0,
              "name" => "dependent",
              "display_name" => "Child Under 26",
              "order" => 3,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e7'),
                  "operator" => :>=,
                  "relationship_name" => :dependent,
                  "count" => 1
                }
              ]
            }
          ],
          "member_relationships" =>
          [
            {
              "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e8'),
              "relationship_name" => :employee,
              "relationship_kinds" => ["self"]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9e9'),
              "relationship_name" => :spouse,
              "relationship_kinds" => ["spouse"]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9ea'),
              "relationship_name" => :domestic_partner,
              "relationship_kinds" => ["life_partner", "domestic_partner"]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e9359a9c324dfc80321d9eb'),
              "relationship_name" => :dependent,
              "relationship_kinds" =>
              [
                "child",
                "adopted_child",
                "foster_child",
                "stepchild",
                "ward"
              ]
            }
          ]
        }
      end

      def fifty_percent_contribution_model
        title = 'Fifty Percent Sponsor Fixed Percent Contribution Model'
        {
          "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917ff3'),
          "product_multiplicities" => ["multiple", "single"],
          "sponsor_contribution_kind" => "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution",
          "contribution_calculator_kind" => "::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator",
          "title" => title,
          "key" => title.downcase.gsub(/\s/, '_'),
          "many_simultaneous_contribution_units" => true,
          "contribution_units" =>
          [
            {
              "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917fef'),
              "_type" =>
              "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => 0.5,
              "name" => "employee",
              "display_name" => "Employee",
              "order" => 0,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917ff4'),
                  "operator" => :==,
                  "relationship_name" => :employee,
                  "count" => 1
                }
              ]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917ff0'),
              "_type" =>
               "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => 0.0,
              "name" => "spouse",
              "display_name" => "Spouse",
              "order" => 1,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917ff5'),
                  "operator" => :>=,
                  "relationship_name" => :spouse,
                  "count" => 1
                }
              ]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917ff1'),
              "_type" =>
              "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => 0.0,
              "name" => "domestic_partner",
              "display_name" => "Domestic Partner",
              "order" => 2,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917ff6'),
                  "operator" => :>=,
                  "relationship_name" => :domestic_partner,
                  "count" => 1
                }
              ]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917ff2'),
              "_type" =>
              "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => 0.0,
              "name" => "dependent",
              "display_name" => "Child Under 26",
              "order" => 3,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917ff7'),
                  "operator" => :>=,
                  "relationship_name" => :dependent,
                  "count" => 1
                }
              ]
            }
          ],
          "member_relationships" =>
          [
            {
              "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917feb'),
              "relationship_name" => :employee,
              "relationship_kinds" => ["self"]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917fec'),
              "relationship_name" => :spouse,
              "relationship_kinds" => ["spouse"]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917fed'),
              "relationship_name" => :domestic_partner,
              "relationship_kinds" => ["life_partner", "domestic_partner"]
            },
            {
              "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917fee'),
              "relationship_name" => :dependent,
              "relationship_kinds" =>
              [
                "child",
                "adopted_child",
                "foster_child",
                "stepchild",
                "ward"
              ]
            }
          ]
        }
      end

      def contribution_models
        [zero_percent_contribution_model, fifty_percent_contribution_model]
      end
    end
  end
end
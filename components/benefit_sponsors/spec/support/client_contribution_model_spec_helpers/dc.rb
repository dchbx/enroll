module BenefitSponsors
  module ClientContributionModelSpecHelpers
    module DC
      def build_contribution_model(title, ee_min_contribution_factor, dep_min_contribution_factor)
        {
          "_id" => BSON::ObjectId.new,
          "product_multiplicities" => ["multiple", "single"],
          "sponsor_contribution_kind" => "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution",
          "contribution_calculator_kind" => "::BenefitSponsors::ContributionCalculators::SimpleShopReferencePlanContributionCalculator",
          "title" => title,
          "key" => title.downcase.gsub(/\s/, '_'),
          "many_simultaneous_contribution_units" => true,
          "contribution_units" =>
          [
            {
              "_id" => BSON::ObjectId.new,
              "_type" =>
              "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => ee_min_contribution_factor,
              "name" => "employee",
              "display_name" => "Employee",
              "order" => 0,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.new,
                  "operator" => :==,
                  "relationship_name" => :employee,
                  "count" => 1
                }
              ]
            },
            {
              "_id" => BSON::ObjectId.new,
              "_type" =>
               "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => dep_min_contribution_factor,
              "name" => "spouse",
              "display_name" => "Spouse",
              "order" => 1,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.new,
                  "operator" => :>=,
                  "relationship_name" => :spouse,
                  "count" => 1
                }
              ]
            },
            {
              "_id" => BSON::ObjectId.new,
              "_type" =>
              "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => dep_min_contribution_factor,
              "name" => "domestic_partner",
              "display_name" => "Domestic Partner",
              "order" => 2,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.new,
                  "operator" => :>=,
                  "relationship_name" => :domestic_partner,
                  "count" => 1
                }
              ]
            },
            {
              "_id" => BSON::ObjectId.new,
              "_type" =>
              "BenefitMarkets::ContributionModels::FixedPercentContributionUnit",
              "minimum_contribution_factor" => dep_min_contribution_factor,
              "name" => "dependent",
              "display_name" => "Child Under 26",
              "order" => 3,
              "default_contribution_factor" => 0.0,
              "member_relationship_maps" =>
              [
                {
                  "_id" => BSON::ObjectId.new,
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
              "_id" => BSON::ObjectId.new,
              "relationship_name" => :employee,
              "relationship_kinds" => ["self"]
            },
            {
              "_id" => BSON::ObjectId.new,
              "relationship_name" => :spouse,
              "relationship_kinds" => ["spouse"]
            },
            {
              "_id" => BSON::ObjectId.new,
              "relationship_name" => :domestic_partner,
              "relationship_kinds" => ["life_partner", "domestic_partner"]
            },
            {
              "_id" => BSON::ObjectId.new,
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

      def list_bill_contribution_model
        build_contribution_model(
          'DC List Bill Shop Contribution Model',
          0.5,
          0
        )
      end

      def zero_percent_contribution_model
        build_contribution_model(
          'Zero Percent Sponsor Fixed Percent Contribution Model',
          0,
          0
        )
      end

      def fifty_percent_contribution_mdoel
        build_contribution_model(
          'Fifty Percent Sponsor Fixed Percent Contribution Model',
          0.5,
          0
        )
      end

      def contribution_models
        [zero_percent_contribution_model, fifty_percent_contribution_mdoel]
      end
    end
  end
end
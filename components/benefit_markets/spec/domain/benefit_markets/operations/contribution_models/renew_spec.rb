# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::ContributionModels::Renew, dbclean: :after_each do

  let(:contribution_params) do
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
          "relationship_kinds" => ["self"],
          "age_threshold" => nil,
          "age_comparison" => nil,
          "disability_qualifier" => nil
        },
        {
          "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917fec'),
          "relationship_name" => :spouse,
          "relationship_kinds" => ["spouse"],
          "age_threshold" => nil,
          "age_comparison" => nil,
          "disability_qualifier" => nil
        },
        {
          "_id" => BSON::ObjectId.from_string('5e938875c324dfdbaf917fed'),
          "relationship_name" => :domestic_partner,
          "relationship_kinds" => ["life_partner", "domestic_partner"],
          "age_threshold" => nil,
          "age_comparison" => nil,
          "disability_qualifier" => nil
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
          ],
          "age_threshold" => 26,
          "age_comparison" => :<,
          "disability_qualifier" => nil
        }
      ]
    }
  end

  context 'when contribution model present' do
    let(:params) { {contribution_model: contribution_params} }

    it 'should renew contribution model' do
      result = subject.call(params)

      expect(result.success?).to be_truthy
      values = result.success
      expect(values[:contribution_model]).to be_a BenefitMarkets::Entities::ContributionModel
      expect(values[:contribution_models]).to be_blank
    end
  end

  context 'when contribution models present' do
    let(:params) { {contribution_models: [contribution_params]} }

    it 'should renew contribution models' do
      result = subject.call(params)

      expect(result.success?).to be_truthy
      values = result.success
      expect(values[:contribution_model]).to be_blank
      expect(values[:contribution_models][0]).to be_a BenefitMarkets::Entities::ContributionModel
    end
  end
end

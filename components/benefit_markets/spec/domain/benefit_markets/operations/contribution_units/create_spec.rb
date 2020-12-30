# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Operations::ContributionUnits::Create, dbclean: :after_each do

  let(:ee_contribution_unit) do
    {
      "_id"=>BSON::ObjectId.new,
      "created_at"=>nil,
      "default_contribution_factor"=>0.0,
      "display_name"=>"Employee",
      "member_relationship_maps"=>[
        {"_id"=>BSON::ObjectId.new, "count"=>1, "created_at"=>nil, "operator"=>:==, "relationship_name"=>:employee, "updated_at"=>nil}
      ],
      "minimum_contribution_factor"=>0.0,
      "name"=>"employee",
      "order"=>0,
      "updated_at"=>nil
    }
  end

  let(:ee_contribution_unit_cap) do
    {
      "_id"=>BSON::ObjectId.new,
      "created_at"=>nil,
      "default_contribution_factor"=>0.0,
      "display_name"=>"Employee",
      "member_relationship_maps"=>[
        {"_id"=>BSON::ObjectId.new, "count"=>1, "created_at"=>nil, "operator"=>:==, "relationship_name"=>:employee, "updated_at"=>nil}
      ],
      "minimum_contribution_factor"=>0.0,
      "name"=>"employee",
      "order"=>0,
      "default_contribution_cap"=>0.0,
      "updated_at"=>nil
    }
  end

  context 'sending required parameters for fixed percent contribution unit' do
    let(:sponsor_contribution_kind)   { "::BenefitSponsors::SponsoredBenefits::FixedPercentSponsorContribution" }
    let(:params)                      { {contribution_unit_params: ee_contribution_unit, sponsor_contribution_kind: sponsor_contribution_kind} }

    it 'should be successful' do
      expect(subject.call(params).success?).to be_truthy
    end

    it 'should create fixed percent contribution unit entity' do
      expect(subject.call(params).success).to be_a BenefitMarkets::Entities::FixedPercentContributionUnit
    end
  end

  context 'sending required parameters for fixed percent with cap contribution unit' do
    let(:cap_sponsor_contribution_kind) { "::BenefitSponsors::SponsoredBenefits::FixedPercentWithCapSponsorContribution" }
    let(:params)                      { {contribution_unit_params: ee_contribution_unit_cap, sponsor_contribution_kind: cap_sponsor_contribution_kind} }

    it 'should be successful' do
      expect(subject.call(params).success?).to be_truthy
    end

    it 'should create percent with cap contribution unit entity' do
      expect(subject.call(params).success).to be_a BenefitMarkets::Entities::PercentWithCapContributionUnit
    end
  end
end
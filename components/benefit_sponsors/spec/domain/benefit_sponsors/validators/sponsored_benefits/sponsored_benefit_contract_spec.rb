# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::SponsoredBenefits::SponsoredBenefitContract do

  let(:product_package_kind)       { :product_package_kind }
  let(:product_option_choice)      { 'product_option_choice' }
  let(:source_kind)                { :source_kind }

  let(:contribution_level) do
    {
      display_name: 'Employee Only', order: 1, contribution_unit_id: BSON::ObjectId.new,
      is_offered: true, contribution_factor: 0.75, min_contribution_factor: 0.5,
      contribution_cap: '0.75', flat_contribution_amount: '227.07'
    }
  end
  let(:contribution_levels)        { [contribution_level] }
  let(:sponsor_contribution)       { {contribution_levels: contribution_levels} }

  let(:pricing_determination)     { {group_size: 4, participation_rate: 75, pricing_determination_tiers: [{pricing_unit_id: BSON::ObjectId.new, price: 227.07}]} }
  let(:pricing_determinations)     { [pricing_determination] }

  let(:missing_params)   { {product_package_kind: product_package_kind, product_option_choice: product_option_choice, source_kind: source_kind, pricing_determinations: pricing_determinations} }
  let(:invalid_params)   { missing_params.merge({sponsor_contribution: {} })}
  let(:error_message1)   { {:reference_product_id => ['is missing'], :sponsor_contribution => ['is missing']} }
  let(:error_message2)   { {:reference_product_id => ['is missing'], :sponsor_contribution => ['must be filled']} }

  context "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message1 }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq error_message2 }
    end
  end

  context "Given valid required parameters" do
    context "with all/required params" do
      let(:all_params) { missing_params.merge({reference_product_id: BSON::ObjectId.new, sponsor_contribution: sponsor_contribution}) }

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end

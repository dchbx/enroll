# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::SponsoredBenefits::PricingDeterminationContract do

  let(:group_size)          { 4 }
  let(:participation_rate)  { 75 }
  let(:pricing_determination_tiers) { [{pricing_unit_id: BSON::ObjectId.new, price: 227.07}] }

  let(:missing_params)   { {group_size: group_size, participation_rate: participation_rate} }
  let(:invalid_params)   { missing_params.merge({ pricing_determination_tiers: {}}) }
  let(:error_message1)   { {:pricing_determination_tiers => ["is missing"]} }
  let(:error_message2)   { {:pricing_determination_tiers => ["must be an array"]} }

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
      let(:all_params)   { missing_params.merge({ pricing_determination_tiers: pricing_determination_tiers}) }

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end

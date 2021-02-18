# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitSponsors::Validators::SponsoredBenefits::PricingDeterminationTierContract do

  let(:pricing_unit_id)  { BSON::ObjectId.new }
  let(:price)            { 227.07 }

  let(:missing_params)   { {pricing_unit_id: pricing_unit_id} }
  let(:invalid_params)   { {pricing_unit_id: BSON::ObjectId.new, price: 'price' } }
  let(:error_message1)   { {:price => ['is missing']} }
  let(:error_message2)   { {:price => ['must be a float']} }

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
      let(:all_params) { {pricing_unit_id: pricing_unit_id, price: price} }

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end

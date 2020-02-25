# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::PricingModels::PricingUnitContract do

  let(:name1)           { 'Title' }
  let(:display_name)    { 'Employee Only' }
  let(:order)           { 1 }

  let(:missing_params)   { {name: name1, display_name: display_name} }
  let(:required_params)  { missing_params.merge({order: order}) }
  let(:invalid_params)   { missing_params.merge({order: 'one'})}
  let(:error_message1)   { {:order => ["is missing"]} }
  let(:error_message2)   { {:order => ["must be an integer"]} }

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

    context "with a required only" do
      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end
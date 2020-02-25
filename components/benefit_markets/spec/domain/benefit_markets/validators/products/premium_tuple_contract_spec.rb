# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::Products::PremiumTupleContract do

  let(:age)            { 12 }
  let(:cost)          { 227.07 }

  let(:missing_params)   { {age: age} }
  let(:required_params)  { missing_params.merge({cost: cost}) }
  let(:error_message)   { {:cost => ["is missing"]} }

  context "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
    end
  end

  context "Given valid required parameters" do

    context "with all required params" do
      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end
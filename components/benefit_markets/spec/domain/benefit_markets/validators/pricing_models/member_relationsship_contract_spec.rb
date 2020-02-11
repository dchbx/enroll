# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitMarkets::Validators::PricingModels::MemberRelationshipContract do

  let(:relationship_name)      { :employee }
  let(:relationship_kinds)     { [{}] }
  let(:age_threshold)          { 18 }
  let(:age_comparison)         { :== }
  let(:disability_qualifier)   { false }

  let(:missing_params)          { {relationship_kinds: relationship_kinds, age_threshold: age_threshold} }
  let(:required_params)         { missing_params.merge({relationship_name: relationship_name}) }
  let(:invalid_params)          { required_params.merge({relationship_name: 123})}
  let(:error_message1)          { {:relationship_name => ["is missing"]} }
  let(:error_message2)          { {:relationship_name => ["must be Symbol"]} }

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

    context "with all params" do
      let(:all_params) do
        required_params.merge({age_comparison: age_comparison, disability_qualifier: disability_qualifier})
      end

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end
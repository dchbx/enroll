# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::ContributionModels::MemberRelationshipMapContract do

  let(:relationship_name)  { :employee }
  let(:count)              { 1 }
  let(:missing_params)     { {_id: BSON::ObjectId.new, relationship_name: relationship_name, count: count} }
  let(:invalid_params)     { missing_params.merge({operator: 'operator'}) }
  let(:error_message1)     { {:operator => ["is missing"]} }
  let(:error_message2)     { {:operator => ["unsupported operator for member relationship map"]} }

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
    let(:required_params) { missing_params.merge({operator: :==}) }

    context "with a required only" do
      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end
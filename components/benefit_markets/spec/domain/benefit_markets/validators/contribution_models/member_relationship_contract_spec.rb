# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitMarkets::Validators::ContributionModels::MemberRelationshipContract do

  let(:relationship_name)   { :Employee }
  let(:relationship_kinds)  { ['self'] }

  let(:missing_params)      { {_id: BSON::ObjectId.new, relationship_name: relationship_name} }
  let(:invalid_params)      { {_id: BSON::ObjectId.new, relationship_name: relationship_name, relationship_kinds: [{}]} }
  let(:required_params)     { {_id: BSON::ObjectId.new, relationship_name: relationship_name, relationship_kinds: relationship_kinds} }
  let(:error_message)       { {:relationship_kinds => ["is missing"]} }
  let(:error_message2)      { {:relationship_kinds => {0 => ["must be a string"]}} }

  context "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message }
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
        required_params.merge({age_threshold: 26, age_comparison: :age_comparison, disability_qualifier: true})
      end

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end
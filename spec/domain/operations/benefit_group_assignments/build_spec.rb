# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::BenefitGroupAssignments::Build, :type => :model, dbclean: :around_each do

  let(:benefit_package_id)            { BSON::ObjectId.new }
  let(:end_on)                        { nil }
  let(:hbx_enrollment_id)             { BSON::ObjectId.new }
  let(:is_active)                     { true }
  let(:start_on)                      { TimeKeeper.date_of_record }

  let(:valid_params)   {{benefit_package_id: benefit_package_id, start_on: start_on, end_on: end_on}}

  let(:missing_params) {valid_params.except(:start_on) }

  let(:invalid_params) {valid_params.merge(start_on: '1234')}

  context "Invalid params" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).failure.to_h.keys).to eq [:start_on] }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).failure.to_h).to eq({:start_on => ["must be a date"]}) }
    end
  end

  context "with valid params" do
    it "should create new BenefitGroupAssignment instance" do
      expect(subject.call(valid_params).success).to be_a Entities::BenefitGroupAssignments::BenefitGroupAssignment
    end
  end
end

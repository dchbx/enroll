# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::BenefitGroupAssignments::BenefitGroupAssignmentContract,  dbclean: :after_each do

  let(:benefit_package_id)            { BSON::ObjectId.new }
  let(:end_on)                        { nil }
  let(:hbx_enrollment_id)             { BSON::ObjectId.new }
  let(:is_active)                     { true }

  let(:missing_params)   { {benefit_package_id: benefit_package_id, end_on: end_on, hbx_enrollment_id: hbx_enrollment_id} }
  let(:invalid_params)   { missing_params.merge({start_on: '1234'})}
  let(:error_message1)   { {:start_on => ["is missing"]} }
  let(:error_message2)   { {:start_on => ["must be a date"]} }

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
      let(:all_params) { missing_params.merge({start_on: TimeKeeper.date_of_record}) }

      it "should pass validation" do
        expect(subject.call(all_params).success?).to be_truthy
        expect(subject.call(all_params).to_h).to eq all_params
      end
    end
  end
end

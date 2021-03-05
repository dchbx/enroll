# frozen_string_literal: true

require "rails_helper"

RSpec.describe Entities::BenefitGroupAssignments::BenefitGroupAssignment do

  context "Given valid required parameters" do

    let(:required_params) do
      {
        start_on: TimeKeeper.date_of_record,
        benefit_package_id: BSON::ObjectId.new
      }
    end

    let(:contract) { Validators::BenefitGroupAssignments::BenefitGroupAssignmentContract.new }

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new BenefitGroupAssignment instance" do
        expect(described_class.new(required_params)).to be_a Entities::BenefitGroupAssignments::BenefitGroupAssignment
      end
    end

    context 'with invalid params' do
      it 'should return an error with message' do
        expect { described_class.new({}) }.to raise_error(Dry::Struct::Error, /:benefit_package_id is missing in Hash input/)
      end
    end
  end
end
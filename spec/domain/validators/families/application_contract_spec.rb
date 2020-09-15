# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Validators::Families::ApplicationContract,  dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_family) }
  let(:family) { person.primary_family }

  let(:applicant) do
    {
      first_name: "James", last_name: "Bond", ssn: "101010101", gender: "male", dob: Date.new(1993, 3, 8),
      is_incarcerated: false, indian_tribe_member: false, citizen_status: "US citizen",
      is_consumer_role: true, same_with_primary:  true, is_applying_coverage: true
    }
  end

  let(:required_params) do
    {
      family_id: family.id, assistance_year: 2020, benchmark_product_id: BSON::ObjectId.new, integrated_case_id: '20000',
      years_to_renew: 2021, applicants: [applicant]
    }
  end
  let(:optional_params) do
    {
      is_ridp_verified: false, renewal_consent_through_year: 2020
    }
  end
  let(:all_params) { required_params.merge(optional_params)}

  context "Given invalid parameter scenarios" do
    context "with empty parameters" do
      it 'should list error for every required parameter' do
        result = subject.call({})
        expect(result.success?).to be_falsey
        expect(result.errors.to_h.keys).to match_array required_params.keys
      end
    end

    context "with optional parameters only" do
      it { expect(subject.call(optional_params).success?).to be_falsey }
      it { expect(subject.call(optional_params).error?(required_params.first[0])).to be_truthy }
    end
  end

  context "Given valid parameters" do
    context "and required parameters only" do
      it { expect(subject.call(required_params).success?).to be_truthy }
      it { expect(subject.call(required_params).to_h).to eq required_params }
    end

    context "and all required and optional parameters" do
      it "should pass validation" do
        result = subject.call(all_params)
        expect(result.success?).to be_truthy
        expect(result.to_h).to eq all_params
      end
    end
  end
end

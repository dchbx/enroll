# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::Families::EligibilityDeterminationContract,  dbclean: :after_each do
  let(:required_params) do
    {
      family_id: BSON::ObjectId.new, assistance_year: 2020, benchmark_product_id: BSON::ObjectId.new, integrated_case_id: '200',
      applicants: [], eligibility_determinations: []
    }
  end

  let(:applicant_params) {
    {
      first_name: "James", last_name: "Bond", gender: "male", dob: Date.new(1993, 3, 8),
      is_incarcerated: false, citizen_status: "US citizen", is_consumer_role: true, same_with_primary:  true,
      is_applying_coverage: true, eligibility_determination_id: BSON::ObjectId.new, magi_medicaid_category: 'test',
      magi_as_percentage_of_fpl: 23.3, magi_medicaid_monthly_income_limit: {}, magi_medicaid_monthly_household_income: {},
      is_without_assistance: true, is_ia_eligible: false, is_medicaid_chip_eligible: false, is_non_magi_medicaid_eligible: false,
      is_totally_ineligible: true, medicaid_household_size: 2
    }
  }

  let(:determination_params) {
    {
      max_aptc: {"cents"=>7169400.0, "currency_iso"=>"USD"}, csr_percent_as_integer: 0, source: 'test',
      aptc_csr_annual_household_income: {"cents"=>7169400.0, "currency_iso"=>"USD"},
      aptc_annual_income_limit: {"cents"=>7169400.0, "currency_iso"=>"USD"},
      csr_annual_income_limit: {"cents"=>7169400.0, "currency_iso"=>"USD"},
      determined_at: Date.new
    }
  }



  let(:all_params) { required_params }

  context "Given invalid parameter scenarios" do
    context "with empty parameters" do
      it 'should list error for every required parameter' do
        result = subject.call({})

        expect(result.success?).to be_falsey
        expect(result.errors.to_h.keys).to match_array required_params.keys
      end
    end

  end

  context "Given valid parameters" do
    context "and required parameters only" do
      it { expect(subject.call(required_params).success?).to be_truthy }
      it { expect(subject.call(required_params).to_h).to eq required_params }
    end

    context "and all required parameters" do
      it "should pass validation" do
        result = subject.call(all_params)
        expect(result.success?).to be_truthy
        expect(result.to_h).to eq all_params
      end
    end
  end

end
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::Families::DeterminationContract,  dbclean: :after_each do
  let(:required_params) do
    {
      max_aptc: {"cents"=>7169400.0, "currency_iso"=>"USD"}, csr_percent_as_integer: 0, source: 'test',
      aptc_csr_annual_household_income: {"cents"=>7169400.0, "currency_iso"=>"USD"},
      aptc_annual_income_limit: {"cents"=>7169400.0, "currency_iso"=>"USD"},
      csr_annual_income_limit: {"cents"=>7169400.0, "currency_iso"=>"USD"},
      determined_at: Date.new
    }
  end

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
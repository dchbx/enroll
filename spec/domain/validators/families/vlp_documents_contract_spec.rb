# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Validators::Families::VlpDocumentContract,  dbclean: :after_each do

  let(:required_params) {{subject: "Invoice"}}

  let(:optional_params) do
    {
      alien_number: "0110200", i94_number: "i94", visa_number: "93749h",
      passport_number: "L1201", sevis_id: "N010", naturalization_number: nil,
      receipt_number: nil, citizenship_number: nil, card_number: nil,
      country_of_citizenship: nil, expiration_date: Date.new(2022, 3, 8), issuing_country: "USA",
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

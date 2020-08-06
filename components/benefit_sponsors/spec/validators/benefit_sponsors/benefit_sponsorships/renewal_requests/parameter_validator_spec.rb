# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::BenefitSponsorships::RenewalRequests::ParameterValidator do
  let(:validator) { BenefitSponsors::BenefitSponsorships::RenewalRequests::ParameterValidator.new }
  let(:benefit_sponsorship_id) { BSON::ObjectId.new }
  let(:new_date) { Date.new(2018, 3, 4) }

  let(:base_valid_params) do
    {
      "new_date" => "2018-03-04",
      "benefit_sponsorship_id" => benefit_sponsorship_id.to_s
    }
  end

  describe "given valid parameters" do
    subject { validator.call(base_valid_params) }

    it "is valid" do
      expect(subject.success?).to be_truthy
    end

    it "has the new date" do
      expect(subject.output[:new_date]).to eq new_date
    end

    it "has the benefit sponsorship id" do
      expect(subject.output[:benefit_sponsorship_id]).to eq benefit_sponsorship_id
    end
  end

  describe "given a bogus benefit sponsorship id" do
    let(:params) do
      base_valid_params.merge({
                                "benefit_sponsorship_id" => "sadfjkjkksef"
                              })
    end

    subject { validator.call(params) }

    it "is invalid" do
      expect(subject.success?).to be_falsey
    end

    it "has an error on the benefit_sponsorship_id" do
      expect(subject.errors.to_h).to have_key(:benefit_sponsorship_id)
    end
  end

  describe "given a bogus date" do
    let(:params) do
      base_valid_params.merge({
                                "new_date" => "2019-51-01"
                              })
    end

    subject { validator.call(params) }

    it "is invalid" do
      expect(subject.success?).to be_falsey
    end

    it "has an error on the new_date" do
      expect(subject.errors.to_h).to have_key(:new_date)
    end
  end
end
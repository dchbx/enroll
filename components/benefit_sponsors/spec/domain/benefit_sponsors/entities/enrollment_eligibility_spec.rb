# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::EnrollmentEligibility do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitSponsors::Validators::EnrollmentEligibilityContract.new }

    let(:effective_date)            { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:market_kind)               { :aca_shop }
    let(:benefit_sponsorship_id)    { BSON::ObjectId.new }
    let(:benefit_application_kind)  { :initial }
    let(:service_area)              { FactoryBot.create(:benefit_markets_locations_service_area) }

    let(:required_params) do
      {
        effective_date: effective_date, market_kind: market_kind, benefit_sponsorship_id: benefit_sponsorship_id,
        benefit_application_kind: benefit_application_kind, service_areas: [service_area.as_json]
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new EnrollmentEligibility instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::EnrollmentEligibility
      end
    end
  end
end
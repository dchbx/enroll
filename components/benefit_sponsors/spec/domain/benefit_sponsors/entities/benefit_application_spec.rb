# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::BenefitApplication do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitSponsors::Validators::BenefitApplications::BenefitApplicationContract.new }

    let(:effective_date)                 { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:oe_start_on)                    { TimeKeeper.date_of_record.beginning_of_month}
    let(:expiration_date)                { effective_date }
    let(:effective_period)               { effective_date..(effective_date + 1.year).prev_day }
    let(:oe_period)                      { oe_start_on..(oe_start_on + 10.days) }      
    let(:terminated_on)                  { effective_date.end_of_month }       
    let(:termination_kind)               { "non_payment"}
    let(:termination_reason)             { "non_payment_termination_reason"}

    let(:required_params) do
      {
        expiration_date: expiration_date, open_enrollment_period: oe_period, aasm_state: :draft, recorded_rating_area_id: BSON::ObjectId.new,
        benefit_sponsor_catalog_id: BSON::ObjectId.new, effective_period: effective_period, recorded_service_area_ids: [BSON::ObjectId.new],
        terminated_on: terminated_on, fte_count: 20, pte_count: 10, msp_count: 1, recorded_sic_code: '034',
        predecessor_id: BSON::ObjectId.new, termination_kind: termination_kind, termination_reason: termination_reason
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new BenefitApplication instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::BenefitApplication
      end
    end
  end
end
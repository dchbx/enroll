# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::BenefitSponsorship do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitSponsors::Validators::BenefitSponsorships::BenefitSponsorshipContract.new }

    let(:effective_date)                 { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:oe_start_on)                    { TimeKeeper.date_of_record.beginning_of_month}
    let(:expiration_date)                { effective_date }
    let(:effective_period)               { effective_date..(effective_date + 1.year).prev_day }
    let(:oe_period)                      { oe_start_on..(oe_start_on + 10.days) }      
    let(:terminated_on)                  { effective_date.end_of_month }       
    let(:termination_kind)               { "non_payment"}
    let(:termination_reason)             { "non_payment_termination_reason"}

    let(:benefit_application) do
      {
        expiration_date: expiration_date, open_enrollment_period: oe_period, aasm_state: :draft, recorded_rating_area_id: BSON::ObjectId.new,
        benefit_sponsor_catalog_id: BSON::ObjectId.new, effective_period: effective_period, recorded_service_area_ids: [BSON::ObjectId.new],
        terminated_on: terminated_on, fte_count: 20, pte_count: 10, msp_count: 1, recorded_sic_code: '034',
        predecessor_id: BSON::ObjectId.new, termination_kind: termination_kind, termination_reason: termination_reason
      }
    end
    let(:required_params) do
      {
        _id: BSON::ObjectId.new, hbx_id: '1234567', aasm_state: :draft, profile_id: BSON::ObjectId.new, source_kind: :self_serve,
        is_no_ssn_enabled: true, market_kind: :aca_shop, organization_id: BSON::ObjectId.new, registered_on: nil,
        benefit_applications: [benefit_application], effective_begin_on: effective_period.min, effective_end_on: effective_period.max,
        ssn_enabled_on: nil , ssn_disabled_on: nil, termination_kind: termination_kind, termination_reason: termination_reason,
        predecessor_id: BSON::ObjectId.new
      }
    end

    let(:required_params_1) { required_params.merge({is_no_ssn_enabled: nil}) }

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new BenefitSponsorship instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::BenefitSponsorship
      end

      it "contract validation should pass when is_no_ssn_enabled is nil" do
        expect(contract.call(required_params_1).to_h).to eq required_params_1
      end

      it "should create new BenefitSponsorship instance when is_no_ssn_enabled is nil" do
        expect(described_class.new(required_params_1)).to be_a BenefitSponsors::Entities::BenefitSponsorship
      end
    end
  end
end
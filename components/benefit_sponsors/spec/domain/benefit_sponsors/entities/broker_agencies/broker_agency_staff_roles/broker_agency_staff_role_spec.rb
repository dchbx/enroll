# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::BrokerAgencies::BrokerAgencyStaffRoles::BrokerAgencyStaffRole do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitSponsors::Validators::BrokerAgencies::BrokerAgencyStaffRoles::BrokerAgencyStaffRoleContract.new }

    let(:required_params) do
      {
        aasm_state: 'broker_agency_pending', benefit_sponsors_broker_agency_profile_id: BSON::ObjectId.new
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new broker staff role instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::BrokerAgencies::BrokerAgencyStaffRoles::BrokerAgencyStaffRole
      end
    end
  end
end
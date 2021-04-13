# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::GeneralAgencies::GeneralAgencyStaffRoles::GeneralAgencyStaffRole do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitSponsors::Validators::GeneralAgencies::GeneralAgencyStaffRoles::GeneralAgencyStaffRoleContract.new }

    let(:required_params) do
      {
        aasm_state: 'broker_agency_pending', benefit_sponsors_general_agency_profile_id: BSON::ObjectId.new, npn: '12345'
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new general agency staff role instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::GeneralAgencies::GeneralAgencyStaffRoles::GeneralAgencyStaffRole
      end
    end
  end
end
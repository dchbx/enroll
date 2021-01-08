# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::Employers::EmployerStaffRoles::EmployerStaffRole do

  context "Given valid required parameters" do

    let(:contract)                  { BenefitSponsors::Validators::Employers::EmployerStaffRoles::EmployerStaffRoleContract.new }

    let(:required_params) do
      {
        is_owner: true, aasm_state: 'applicant', benefit_sponsor_employer_profile_id: BSON::ObjectId.new,
        coverage_record: {
          ssn: nil,
          gender: nil,
          dob: nil,
          hired_on: nil,
          is_applying_coverage: false,
          address: {
            kind: nil,
            address_1: nil,
            address_2: nil,
            address_3: nil,
            city: nil,
            county: nil,
            state: nil,
            location_state_code: nil,
            full_text: nil,
            zip: nil,
            country_name: nil
          },
          email: {
            kind: nil,
            address: nil
          }
        }
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new employer staff role instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::Employers::EmployerStaffRoles::EmployerStaffRole
      end
    end
  end
end
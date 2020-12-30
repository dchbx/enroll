# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitSponsors::Entities::Organization do

  context "Given valid required parameters" do

    let(:contract)      { BenefitSponsors::Validators::Organizations::OrganizationContract.new }
    let(:required_params) do
      {
        hbx_id: '1234321',  legal_name: 'abc_organization', entity_kind: :limited_liability_corporation,
        fein: '987654321', site_id: BSON::ObjectId.new, dba: nil, home_page: nil
      }
    end

    context "with required only" do

      it "contract validation should pass" do
        expect(contract.call(required_params).to_h).to eq required_params
      end

      it "should create new Organization instance" do
        expect(described_class.new(required_params)).to be_a BenefitSponsors::Entities::Organization
      end
    end
  end
end
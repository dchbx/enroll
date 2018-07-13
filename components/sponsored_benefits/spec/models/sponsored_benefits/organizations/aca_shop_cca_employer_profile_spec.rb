require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::AcaShopCcaEmployerProfile, type: :model, dbclean: :after_each  do

    let(:sic_code)        { '1111' }


    let(:valid_params) do 
      {
        sic_code: sic_code,
      }
    end

    subject {
        described_class.new(valid_params)
      }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end


    context "Embedded in a Plan Design Proposal" do
      let(:title)                     { 'New proposal' }
      let(:cca_employer_profile)      { SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new(sic_code: sic_code) }

      let(:plan_design_organization)  { Organizations::PlanDesignOrganization.new(fein: fein, legal_name: legal_name, sic_code: sic_code) }
      let(:plan_design_proposal)      { plan_design_organization.plan_design_proposals.build(title: title, profile: cca_employer_profile) }
      let(:profile)                   { plan_design_organization.plan_design_proposals.first.profile }

      it "should save without error"
      it "should be findable"

    end

  end
end

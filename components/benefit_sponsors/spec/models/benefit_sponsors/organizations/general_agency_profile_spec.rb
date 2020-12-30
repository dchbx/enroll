# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  RSpec.describe Organizations::GeneralAgencyProfile, type: :model do
    it {should validate_presence_of(:market_kind)}

    context "#find" do
      let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }

      it "should find general agency profile" do
        profile_id = general_agency.profiles.first.id
        expect(subject.class.find(profile_id)).to eq general_agency.profiles.first
      end
    end

    context "#filter_by" do
      let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
      let(:status) { 'is_applicant' }

      it "should return only status inputed profiles" do
        expect(BenefitSponsors::Organizations::GeneralAgencyProfile.filter_by(status).map(&:aasm_state).uniq).to eq ["is_applicant"]
      end
    end

    context "#primary_staff" do
      let(:general_agency) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
      let(:ga_profile)     { general_agency.general_agency_profile }
      let(:primary_person) {FactoryBot.create(:person)}
      let(:staff_person) {FactoryBot.create(:person)}

      before do
        FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: ga_profile.id, is_primary: true, person: primary_person)
        FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: ga_profile.id, is_primary: false, person: staff_person)
      end


      it "should return only primary_staff GA" do
        expect(general_agency.general_agency_profile.primary_staff.is_primary).to eq true
      end
    end
  end
end

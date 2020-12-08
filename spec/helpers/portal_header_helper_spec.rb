require 'rails_helper'

RSpec.describe PortalHeaderHelper, :type => :helper, dbclean: :after_each do

  describe "portal_display_name" do

    let(:signed_in?){ true }

    context "has_employer_staff_role?" do
      let(:site_key)         { Settings.site.key }
      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, site_key) }
      let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_profile)    { benefit_sponsor.employer_profile }
      let!(:employer_staff_role){ FactoryBot.create(:employer_staff_role, aasm_state:'is_closed', :benefit_sponsor_employer_profile_id=>employer_profile.id)}
      let!(:benefit_sponsor2)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_profile2)    { benefit_sponsor2.employer_profile }
      let!(:employer_staff_role2){ FactoryBot.create(:employer_staff_role, aasm_state:'is_active', :benefit_sponsor_employer_profile_id=>employer_profile2.id)}
      let!(:this_person) { FactoryBot.build(:person, :employer_staff_roles => [employer_staff_role, employer_staff_role2]) }
      let!(:current_user) { FactoryBot.build(:user, :person=>this_person)}
      let!(:emp_id) {current_user.person.active_employer_staff_roles.first.benefit_sponsor_employer_profile_id}
      let!(:employee_role) { FactoryBot.build(:employee_role, person: current_user.person, employer_profile: employer_profile)}

      it "should have I'm an Employer link when user has active employer_staff_role" do
        expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/benefit_sponsors/profiles/employers/employer_profiles/" + emp_id.to_s + "?tab=home\"><img src=\"/images/icons/icon-business-owner.png\" /> &nbsp; I'm an Employer</a>"
      end

      it "should have I'm an Employee link when user has active employee_staff_role" do
        allow(current_user.person).to receive(:active_employee_roles).and_return [employee_role]
        expect(portal_display_name('')).to eq "<a class=\"portal\" href=\"/families/home\"><img src=\"/images/icons/#{site_key}-icon-individual.png\" /> &nbsp; I'm an Employee</a>"
      end

      it "should have Welcome prompt when user has no active role" do
        allow(current_user).to receive(:has_employer_staff_role?).and_return(false)
        expect(portal_display_name(controller)).to eq "<a class='portal'>#{Settings.site.byline}</a>"
      end
    end

    context "has_consumer_role?" do
      let(:current_user) { FactoryBot.build(:user, :identity_verified_date => Time.now)}
      before(:each) do
        allow(current_user).to receive(:has_consumer_role?).and_return(true)
        allow(controller).to receive(:controller_path).and_return("insured")
      end

      it "should have Individual and Family link when user completes RIDP and Consent form" do
        expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/families/home\"><img src=\"/images/icons/icon-family.png\" /> &nbsp; Individual and Family</a>"
      end

      it "should not have Individual and Family link for users with no identity_verified_date" do
        current_user.identity_verified_date = nil
        current_user.save
        expect(portal_display_name(controller)).to eq "<a class='portal'><img src=\"/images/icons/icon-family.png\" /> &nbsp; Individual and Family</a>"
      end
    end

    context "has_general_agency_staff_role?" do
      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, :with_site) }
      let!(:general_agency_profile)    { benefit_sponsor.general_agency_profile }
      let!(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: 'active', person: person)}
      let!(:person) { FactoryBot.build(:person, user: current_user) }
      let!(:current_user) { FactoryBot.build(:user)}

      before(:each) do
        allow(controller).to receive(:controller_path).and_return("general_agencies")
      end

      it "should have I'm a General Agency link when user has active employer_staff_role" do
        expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/benefit_sponsors/profiles/general_agencies/general_agency_profiles/" + general_agency_profile.id.to_s + "\"><img src=\"/images/icons/icon-expert.png\" /> &nbsp; I'm a General Agency</a>"
      end

      it "should have Welcome prompt when user has no active role" do
        allow(current_user).to receive(:has_general_agency_staff_role?).and_return(false)
        expect(portal_display_name(controller)).to eq "<a class='portal'>#{Settings.site.byline}</a>"
      end
    end

  end
end

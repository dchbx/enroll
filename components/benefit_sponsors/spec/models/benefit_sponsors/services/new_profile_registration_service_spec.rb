require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::NewProfileRegistrationService, type: :model, :dbclean => :after_each do

    subject { BenefitSponsors::Services::NewProfileRegistrationService }
    let!(:security_question)  { FactoryBot.create_default :security_question }
    let!(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
    let!(:general_org) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
    let!(:employer_profile) {general_org.employer_profile}
    let!(:user) { FactoryBot.create(:user)}
    let!(:person) { FactoryBot.create(:person, emails: [FactoryBot.build(:email, kind: 'work')], user: user) }
    let!(:active_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id, person: person)}
    let!(:broker_role) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }
    let!(:broker_agency_staff_role) { FactoryBot.build(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person)}
    let(:broker_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
    let!(:broker_agency_profile) {broker_agency.broker_agency_profile}
    let!(:general_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site)}
    let!(:general_agency_profile) {general_agency.profiles.first }
    let(:general_role) {FactoryBot.create(:general_agency_staff_role, aasm_state: "active", benefit_sponsors_general_agency_profile_id: general_agency_profile.id)}
    let!(:primary_general_agency_staff_role) { FactoryBot.build(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: "active",  person: person, is_primary: true)}

    def agency(type)
      case type
      when "benefit_sponsor"
        employer_profile
      when "broker_agency"
        broker_agency_profile
      when "general_agency"
        general_agency_profile
      end
    end

    shared_examples_for "should return profile type" do |profile_type|

      it "profile_type #{profile_type}" do
        # params = { profile_id: profile_type == "benefit_sponsor" ? employer_profile.id : broker_agency_profile.id}
        params = {profile_id: agency(profile_type).id}
        service = subject.new params
        expect(service.pluck_profile_type params[:profile_id]).to eq profile_type
      end

    end

    describe ".pluck_profile_type" do
      it_behaves_like "should return profile type", "benefit_sponsor"
      it_behaves_like "should return profile type", "broker_agency"
      it_behaves_like "should return profile type", "general_agency"
    end

    shared_examples_for "should return form for profile" do |profile_type|

      it "should return form for existing #{profile_type} type" do
        # params = { profile_id: profile_type == "benefit_sponsor" ? employer_profile.id : broker_agency_profile.id}
        params = {profile_id: agency(profile_type).id, profile_type: profile_type}
        service = subject.new params
        build_hash = service.build params
        # expect(build_hash[:organization][:legal_name]).to eq profile_type == "benefit_sponsor" ?  employer_profile.legal_name : broker_agency_profile.legal_name
        expect(build_hash[:organization][:legal_name]).to eq agency(profile_type).legal_name
      end

      it "should return new form for #{profile_type} type" do
        params = { profile_type: profile_type}
        service = subject.new params
        build_hash = service.build params
        expect(build_hash[:profile_type]).to eq profile_type
        expect(build_hash[:organization][:legal_name]).to eq nil
      end
    end

    describe ".build" do
      it_behaves_like "should return form for profile", "benefit_sponsor"
      it_behaves_like "should return form for profile", "broker_agency"
      it_behaves_like "should return form for profile", "general_agency"
    end

    shared_examples_for "should find profile and return form for profile" do |profile_type|

      it "should return form for #{profile_type} type" do
        params = { profile_id: agency(profile_type).id, profile_type:profile_type}
        service = subject.new params
        find_hash = service.find
        expect(find_hash[:profile_type]).to eq profile_type
        expect(find_hash[:organization][:legal_name]).to eq agency(profile_type).legal_name
      end
    end

    describe ".find" do
      it_behaves_like "should find profile and return form for profile", "benefit_sponsor"
      it_behaves_like "should find profile and return form for profile", "broker_agency"
      it_behaves_like "should find profile and return form for profile", "general_agency"
    end


    describe ".is_benefit_sponsor_already_registered?" do
      context "Should return when person found" do
        before :each do
          allow(user).to receive(:person).and_return(person)
          @form = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.new(profile_type: "benefit_sponsor")
          @result = subject.new(@form).is_benefit_sponsor_already_registered?(user, @form)
        end

        it 'should return false for when found employer profile id' do
          expect(@result).to eq false
        end
      end
    end

    describe "has_general_agency_staff_role_for_profile?" do
      context "check for general agency staff role" do
        let(:general_agency_person) { FactoryBot.create(:person, emails:[FactoryBot.build(:email, kind:'work')],employer_staff_roles:[active_employer_staff_role]) }
        let(:general_agency_user) { FactoryBot.create(:user, :person => general_agency_person)}
        it "has general_agency_staff_role" do
          expect(subject.new.has_general_agency_staff_role_for_profile?(general_agency_user,general_agency_profile)).to eq false
        end
      end
    end

    describe ".has_broker_agency_staff_role_for_profile" do
      context "Person with Broker agency staff roles" do

        it "should return true if broker staff is assigned to a broker agency profile" do
          params = { profile_id: broker_agency_profile.id, profile_type: "broker_agency_staff" }
          service = subject.new params
          expect(service.has_broker_agency_staff_role_for_profile(user, broker_agency_profile)). to eq true
        end

        it "should return true if broker staff is assigned to a broker agency profile" do
          params = { profile_id: broker_agency_profile.id, profile_type: "broker_agency_staff" }
          service = subject.new params
          expect(service.has_broker_agency_staff_role_for_profile(user, broker_agency_profile)). to eq true
        end

        it "should return false if broker staff is not assigned to a broker agency profile" do
          person.broker_agency_staff_roles.each{|staff| staff.update_attributes(benefit_sponsors_broker_agency_profile_id: nil)}
          params = { profile_id: broker_agency_profile.id, profile_type: "broker_agency_staff" }
          service = subject.new params
          expect(service.has_broker_agency_staff_role_for_profile(user, broker_agency_profile)). to eq false
        end
      end
    end

    describe ".is_broker_agency_registered?" do
      let(:profile_form) {BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.new(profile_id: broker_agency_profile.id)}
      let(:user1) { FactoryBot.create(:user)}
      let(:person1) { FactoryBot.create(:person, emails: [FactoryBot.build(:email, kind: 'work')], user: user1) }
      let!(:broker_agency_staff_role) { FactoryBot.build(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, aasm_state: "coverage_terminated",  person: person1)}


      it 'should return false if broker staff role or broker role exists for the user' do
        params = { profile_id: broker_agency_profile.id, profile_type: "broker_agency_staff"}
        service = subject.new params
        expect(service.is_broker_agency_registered?(user, profile_form)). to eq false
      end

      it 'should return true if broker staff role or broker role does not exists for the user' do
        params = { profile_id: broker_agency_profile.id, profile_type: "broker_agency_staff"}
        service = subject.new params
        expect(service.is_broker_agency_registered?(user1, profile_form)). to eq true
      end
    end

    describe ".is_general_agency_registered?" do
      let(:profile_form) {BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.new(profile_id: general_agency_profile.id)}
      let(:user1) { FactoryBot.create(:user)}
      let(:general_agency_staff_role) { FactoryBot.build(:general_agency_staff_role, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, aasm_state: "coverage_terminated")}
      let!(:person1) do
        FactoryBot.create(:person, emails: [FactoryBot.build(:email, kind: 'work')], user: user1, general_agency_staff_roles: [ general_agency_staff_role ])
      end

      it 'should return false if general staff role or general role exists for the user' do
        params = { profile_id: general_agency_profile.id, profile_type: "general_agency_staff"}
        service = subject.new params
        expect(service.is_general_agency_registered?(user, profile_form)). to eq false
      end

      it 'should return true if general staff role or general role does not exists for the user' do
        params = { profile_id: general_agency_profile.id, profile_type: "general_agency_staff"}
        service = subject.new params
        expect(service.is_general_agency_registered?(user1, profile_form)). to eq true
      end
    end

    describe ".is_staff_for_agency?" do
      context "Staff for broker agency profile" do

        it "should return true if broker staff is assigned to a broker agency profile" do
          params = { profile_id: broker_agency_profile.id, profile_type: "broker_agency_staff" }
          service = subject.new params
          expect(service.is_staff_for_agency?(user, nil)). to eq true
        end

        it "should return false if broker staff is not assigned to a broker agency profile" do
          person.broker_agency_staff_roles.each{|staff| staff.update_attributes(benefit_sponsors_broker_agency_profile_id: nil)}
          params = { profile_id: broker_agency_profile.id, profile_type: "broker_agency_staff" }
          service = subject.new params
          expect(service.is_staff_for_agency?(user, nil)). to eq false
        end
      end
    end

    describe ".has_employer_staff_role_for_profile??" do
      context "Staff for Employer profile" do

        it "should return true if employer staff is active to a employer profile" do
          params = { profile_id: employer_profile.id, profile_type: "employer_profile" }
          service = subject.new params
          expect(service.is_staff_for_agency?(user, employer_profile)). to eq true
        end

        it "should return false if employer staff is not active to a employer profile" do
          person.employer_staff_roles.first.update_attributes(aasm_state: "is_closed")
          params = { profile_id: employer_profile.id, profile_type: "employer_profile" }
          service = subject.new params
          expect(service.is_staff_for_agency?(user, employer_profile)). to eq false
        end
      end
    end

    describe ".is_general_agency_staff_for_employer?" do

      let(:plan_design_organization) do
        FactoryBot.create(
          :sponsored_benefits_plan_design_organization,
          owner_profile_id: broker_agency_profile.id,
          sponsor_profile_id: employer_profile.id
        )
      end

      let(:plan_design_organization_with_assigned_ga) {
        plan_design_organization.general_agency_accounts.create(
          start_on: TimeKeeper.date_of_record,
          broker_role_id: broker_agency_profile.primary_broker_role.id
        ).tap do |account|
          account.general_agency_profile = general_agency_profile
          account.broker_agency_profile = broker_agency_profile
          account.save
        end
        plan_design_organization
      }

      let(:params) {{ profile_id: employer_profile.id, profile_type: "benefit_sponsor" }}
      let(:service) {subject.new params}

      before do
        allow(person).to receive(:active_general_agency_staff_roles).and_return([primary_general_agency_staff_role])
        allow(employer_profile).to receive(:general_agency_accounts).and_return(plan_design_organization_with_assigned_ga.general_agency_accounts)
        allow(service).to receive(:load_profile) do
          service.instance_variable_set(:@profile, employer_profile)
        end
      end

      it "should return true if general agency staff is assigned to a general agency profile" do
        expect(service.is_general_agency_staff_for_employer?(user, nil)).to eq true
      end

      it "should return false if general agency staff is not assigned to a general agency profile" do
        person.general_agency_staff_roles.each{|staff| staff.update_attributes(benefit_sponsors_general_agency_profile_id: nil)}
        expect(service.is_general_agency_staff_for_employer?(user, nil)).to eq false
      end

      it "should return true if employer staff is active to a employer profile" do
        params = { profile_id: general_agency_profile.id, profile_type: "general_agency" }
        service = subject.new params
        expect(service.has_general_agency_staff_role_for_profile?(user, general_agency_profile)). to eq true
      end

      it "should return false if employer staff is not active to a employer profile" do
        person.general_agency_staff_roles.first.update_attributes(aasm_state: "general_agency_terminated")
        params = { profile_id: general_agency_profile.id, profile_type: "general_agency" }
        service = subject.new params
        expect(service.has_general_agency_staff_role_for_profile?(user, general_agency_profile)). to eq false
      end
    end
  end
end

require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::NewProfileRegistrationService, type: :model, :dbclean => :after_each do

    subject { BenefitSponsors::Services::NewProfileRegistrationService }
    let!(:security_question)  { FactoryGirl.create_default :security_question }

    let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :cca) }
    let!(:general_org) {FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
    let!(:employer_profile) {general_org.employer_profile}
    let!(:active_employer_staff_role) {FactoryGirl.build(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id)}
    let(:broker_agency) {FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
    let!(:broker_agency_profile) {broker_agency.broker_agency_profile}
    let!(:broker_role) { FactoryGirl.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }
    let(:person) { FactoryGirl.create(:person, emails:[FactoryGirl.build(:email, kind:'work')],employer_staff_roles:[active_employer_staff_role],broker_role:broker_role) }
    let(:user) { FactoryGirl.create(:user, :person => person)}

    shared_examples_for "should return profile type" do |profile_type|

      it "profile_type #{profile_type}" do
        params = { profile_id: profile_type == "benefit_sponsor" ? employer_profile.id : broker_agency_profile.id}
        service = subject.new params
        expect(service.pluck_profile_type params[:profile_id]).to eq profile_type
      end

    end

    describe ".pluck_profile_type" do
      it_behaves_like "should return profile type", "benefit_sponsor"
      it_behaves_like "should return profile type", "broker_agency"
    end

    shared_examples_for "should return form for profile" do |profile_type|

      it "should return form for existing #{profile_type} type" do
        params = { profile_id: profile_type == "benefit_sponsor" ? employer_profile.id : broker_agency_profile.id}
        service = subject.new params
        build_hash = service.build params
        expect(build_hash[:profile_type]).to eq profile_type
        expect(build_hash[:organization][:legal_name]).to eq profile_type == "benefit_sponsor" ?  employer_profile.legal_name : broker_agency_profile.legal_name
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
    end

    shared_examples_for "should find profile and return form for profile" do |profile_type|

      it "should return form for #{profile_type} type" do
        params = { profile_id: profile_type == "benefit_sponsor" ? employer_profile.id.to_s : broker_agency_profile.id, profile_type:profile_type}
        service = subject.new params
        find_hash = service.find
        expect(find_hash[:profile_type]).to eq profile_type
        expect(find_hash[:organization][:legal_name]).to eq profile_type == "benefit_sponsor" ?  employer_profile.legal_name : broker_agency_profile.legal_name
      end
    end

    describe ".find" do
      it_behaves_like "should find profile and return form for profile", "benefit_sponsor"
      it_behaves_like "should find profile and return form for profile", "broker_agency"
    end
  end
end

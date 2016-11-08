require 'rails_helper'

RSpec.describe "_employer_broker_widget.html.erb" do
  let(:organization) { FactoryGirl.build_stubbed(:organization) }
  let(:employer_profile) { FactoryGirl.build_stubbed(:employer_profile) }
  let(:plan_year) { FactoryGirl.build_stubbed(:plan_year, employer_profile: employer_profile) }
  let(:broker_agency_account) { FactoryGirl.build_stubbed(:broker_agency_account) }
  let(:broker_agency_profile) { FactoryGirl.build_stubbed(:broker_agency_profile, organization: organization) }

  context 'employer profile with no broker selected' do
    before do
      assign(:employer_profile, employer_profile)
      assign(:broker_agency_accounts, [])
      allow(employer_profile).to receive(:broker_agency_profile).and_return(nil)
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true))
      render 'employers/employer_profiles/employer_broker_widget'
    end

    it "should display broker widget for consumer" do
      expect(rendered).to match /select a broker/i
      expect(rendered).to match /no broker/i
    end
  end

  context 'employer profile with broker selected' do
    before do
      assign(:employer_profile, employer_profile)
      assign(:broker_agency_accounts, [broker_agency_account])
      allow(employer_profile).to receive(:broker_agency_profile).and_return(broker_agency_profile)
      allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true))
      render 'employers/employer_profiles/employer_broker_widget'
    end

    it "should display broker information to employer" do
      expect(rendered).to match (broker_agency_account.writing_agent.email.address)
      expect(rendered).to match (broker_agency_account.writing_agent.person.work_phone.area_code)
      expect(rendered).to match (broker_agency_profile.legal_name.titleize)
    end
  end

end

require 'rails_helper'

RSpec.describe "broker_agencies/profiles/_general_agencies.html.erb", dbclean: :after_each do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }
  
  context "without default_general_agency_profile" do
    before :each do
      allow(broker_agency_profile).to receive(:default_general_agency_profile).and_return nil
      assign :general_agency_profiles, [general_agency_profile]
      assign :broker_agency_profile, broker_agency_profile
      allow(view).to receive(:policy_helper).and_return(double("Policy", modify_admin_tabs?: true))
      render template: "broker_agencies/profiles/_general_agencies.html.erb"
    end

    it 'should have title' do
      expect(rendered).to have_selector('h3', text: 'General Agencies')
    end

    it "should have button of clear default ga" do
      expect(rendered).to have_selector('a', text: 'Clear Default GA')
    end

    it "should have general_agency_profile" do
      expect(rendered).to have_selector('td', text: "#{general_agency_profile.dba}")
      expect(rendered).to have_selector('td', text: "#{general_agency_profile.fein}")
    end

    it "should have link of set default ga" do
      expect(rendered).to have_selector('a', text: 'Select Default GA')
    end

    it "should have hint msg for select default GA" do
      expect(rendered).to have_content("You do not have default GA, to select your default GA click \"Select Default GA\" under your desired agency")
    end
  end


context "without default_general_agency_profile, not updateable" do
    before :each do
      allow(broker_agency_profile).to receive(:default_general_agency_profile).and_return nil
      assign :general_agency_profiles, [general_agency_profile]
      assign :broker_agency_profile, broker_agency_profile
      allow(view).to receive(:policy_helper).and_return(double("Policy", modify_admin_tabs?: false))
      render template: "broker_agencies/profiles/_general_agencies.html.erb"
    end

    it 'should have title' do
      expect(rendered).to have_selector('h3', text: 'General Agencies')
    end

    it "should NOT have click able button of clear default ga" do
      expect(rendered).to have_selector('.blocking', text: 'Clear Default GA')
    end

    it "should have general_agency_profile" do
      expect(rendered).to have_selector('td', text: "#{general_agency_profile.dba}")
      expect(rendered).to have_selector('td', text: "#{general_agency_profile.fein}")
    end

    it "should NOT have link of set default ga" do
      expect(rendered).to have_selector('.blocking', text: 'Select Default GA')
    end

    it "should have hint msg for select default GA" do
      expect(rendered).to have_content("You do not have default GA, to select your default GA click \"Select Default GA\" under your desired agency")
    end
  end

  context "with default_general_agency_profile" do
    before :each do
      allow(broker_agency_profile).to receive(:default_general_agency_profile).and_return general_agency_profile
      assign :general_agency_profiles, [general_agency_profile]
      assign :broker_agency_profile, broker_agency_profile
      assign :notice, "Changing default general agencies may take a few minutes to update all employers."
      allow(view).to receive(:policy_helper).and_return(double("Policy", modify_admin_tabs?: true))
      render template: "broker_agencies/profiles/_general_agencies.html.erb"
    end

    it 'should have title' do
      expect(rendered).to have_selector('h3', text: 'General Agencies')
    end

    it "should have button of clear default ga" do
      expect(rendered).to have_selector('a', text: 'Clear Default GA')
    end

    it "should have general_agency_profile" do
      expect(rendered).to have_selector('td', text: "#{general_agency_profile.dba}")
      expect(rendered).to have_selector('td', text: "#{general_agency_profile.fein}")
    end

    it "should show Default GA" do
      expect(rendered).to have_selector('td', text: 'Default GA')
    end

    it "should have hint msg for select default GA" do
      expect(rendered).to have_content("#{broker_agency_profile.legal_name} - this is your default GA, to change your default GA click \"Select Default GA\" under your desired agency")
    end

    it "should show notice" do
      expect(rendered).to have_selector('.alert-warning')
      expect(rendered).to have_content("Changing default general agencies may take a few minutes to update all employers.")
    end
  end
end

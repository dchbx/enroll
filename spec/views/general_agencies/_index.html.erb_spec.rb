require 'rails_helper'

if ExchangeTestingConfigurationHelper.general_agency_enabled?
RSpec.describe "general_agencies/profiles/_families.html.erb", dbclean: :after_each do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  before :each do
    assign :general_agency_profiles, Kaminari.paginate_array([general_agency_profile]).page(0)
    Settings.aca.general_agency_enabled = true
    Enroll::Application.reload_routes!
    render template: "general_agencies/profiles/_index.html.erb"
  end
  context "individual market is enabled" do
    it 'should have title' do
      expect(rendered).to have_selector('h3', text: 'General Agencies')
    end
    it 'should show general_agencies fields' do
      expect(rendered).to have_selector('th', text: 'Legal Name')
      expect(rendered).to have_selector('th', text: 'Fein')
    end
    it 'should show general_agency_profile info' do
      expect(rendered).to have_selector('a', text: "#{general_agency_profile.legal_name}")
    end
    it "should have status bar" do
      expect(rendered).to have_selector('div.button-group-wrapper')
      expect(rendered).to have_content('Applicant')
      expect(rendered).to have_content('Certified')
      expect(rendered).to have_content('Decertified')
      expect(rendered).to have_content('Pending')
      expect(rendered).to have_content('All')
    end
    it "should show the state of general_agency_profile" do
      expect(rendered).to have_selector('td', text: "#{general_agency_profile.current_state}")
    end
    it "should have input for status" do
      expect(rendered).to have_selector('input[value="is_applicant"]')
      expect(rendered).to have_selector('input[value="is_approved"]')
      expect(rendered).to have_selector('input[value="is_rejected"]')
      expect(rendered).to have_selector('input[value="is_suspended"]')
      expect(rendered).to have_selector('input[value="all"]')
    end
  end
end
end

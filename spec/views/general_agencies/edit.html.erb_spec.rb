require "rails_helper"

if ExchangeTestingConfigurationHelper.general_agency_enabled?
RSpec.describe "general_agencies/profiles/edit.html.erb" do
  let(:organization) {FactoryGirl.create(:organization)}
  let(:general_agency_profile) {FactoryGirl.create(:general_agency_profile, :with_staff, organization: organization)}

  before :each do
    org_form = Forms::GeneralAgencyProfile.find(general_agency_profile.id)
    assign :organization, org_form
    assign :general_agency_profile, general_agency_profile
    assign :id, general_agency_profile.id
    Settings.aca.general_agency_enabled = true
    Enroll::Application.reload_routes!
    render template: "general_agencies/profiles/edit.html.erb"
  end

  it "should have title" do
    expect(rendered).to have_selector('h4', text: 'Personal Information')
    expect(rendered).to have_selector('h4', text: 'General Agency Information')
  end
  it "should have language select" do
    expect(rendered).to have_selector('#general_agency_language_select')
  end
  it "should have organization details displayed" do
    expect(rendered).to have_selector("#organization_first_name", count: 1)
  end
  it "should have a hidden field organization id" do
    expect(rendered).to have_selector("[name='organization[id]']", count: 1)
  end
end
end

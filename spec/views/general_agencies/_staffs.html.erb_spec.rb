require 'rails_helper'

if ExchangeTestingConfigurationHelper.general_agency_enabled?
RSpec.describe "general_agencies/profiles/_staffs.html.erb" do
  let(:staff) { FactoryGirl.create(:general_agency_staff_role) }
  before :each do
    assign :staffs, [staff]
    Settings.aca.general_agency_enabled = true
    Enroll::Application.reload_routes!
    render template: "general_agencies/profiles/_staffs.html.erb"
  end

  it 'should have title' do
    expect(rendered).to have_selector('h3', text: 'General Agency Staff')
  end

  it 'should show staff info' do
    expect(rendered).to have_selector('a', text: "#{staff.person.first_name} #{staff.person.last_name}")
  end
end
end

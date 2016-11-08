require 'rails_helper'

RSpec.describe "broker_agencies/profiles/_assign.html.erb", dbclean: :after_each do
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }

  before :each do
    assign :employers, Kaminari.paginate_array(EmployerProfile.all).page(0)
    assign :broker_agency_profile, broker_agency_profile
    assign :general_agency_profiles, [general_agency_profile]
    allow(view).to receive(:policy_helper).and_return(double("Policy", modify_admin_tabs?: true))
    render template: "broker_agencies/profiles/_assign.html.erb"
  end

  it 'should have title' do
    expect(rendered).to have_selector('h2', text: 'Assign')
    expect(rendered).to have_selector('h3', text: 'General Agencies')
    expect(rendered).to have_selector('h3', text: 'Employers')
  end

  it "should have content" do
    expect(rendered).to have_content('HBX Acct')
    expect(rendered).to have_content('Legal Name')
    expect(rendered).to have_content('Assigned Agency')
  end
end

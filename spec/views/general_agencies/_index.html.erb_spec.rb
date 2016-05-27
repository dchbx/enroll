require 'rails_helper'

RSpec.describe "general_agencies/profiles/_families.html.erb", dbclean: :after_each do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  before :each do
    assign :general_agency_profiles, Kaminari.paginate_array([general_agency_profile]).page(0)
    render template: "general_agencies/profiles/_index.html.erb"
  end

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
end

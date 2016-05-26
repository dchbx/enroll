require 'rails_helper'

RSpec.describe "general_agencies/profiles/_families.html.erb", dbclean: :after_each do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let(:family) { FactoryGirl.build(:family, :with_primary_family_member) }
  before :each do
    assign :families, [family]
    assign :general_agency_profile, general_agency_profile
    assign :page_alphabets, ['A', 'B']
    render template: "general_agencies/profiles/_families.html.erb"
  end

  it 'should have title' do
    expect(rendered).to have_selector('h3', text: 'Family')
  end

  it 'should show general_agencies fields' do
    expect(rendered).to have_selector('th', text: 'Name')
    expect(rendered).to have_selector('th', text: 'SSN')
    expect(rendered).to have_selector('th', text: 'Registered?')
  end

  it 'should show page alphabet links' do
    expect(rendered).to have_selector('a', text: 'A')
    expect(rendered).to have_selector('a', text: 'B')
  end
end

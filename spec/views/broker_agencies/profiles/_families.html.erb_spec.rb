require 'rails_helper'

RSpec.describe "broker_agencies/profiles/_families.html.erb"  do |variable|
  before :each do
    stub_template "_families_table_for_broker.html.erb" => ''
    @page_alphabets = ['XXX', 'YYY']
    @broker_agency_profile = FactoryGirl.create(:broker_agency_profile)
    render template: "broker_agencies/profiles/_families.html.erb" 
  end

  it 'should have title Families' do
    expect(rendered).to have_selector('h3', text: 'Families')
  end

  it 'should not reference enrollment' do
    expect(rendered).not_to have_selector('p', text: 'working on an enrollment')
  end

  it 'should not see consumer column' do
    expect(rendered).not_to have_text("consumer")
  end
end

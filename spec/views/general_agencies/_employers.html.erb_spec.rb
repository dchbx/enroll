# require 'rails_helper'

# RSpec.describe "general_agencies/profiles/_employers.html.erb" do
#   let(:employer) { FactoryGirl.create(:employer_profile) }
#   let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }
#   before :each do
#     allow(employer).to receive(:broker_agency_profile).and_return(broker_agency_profile)
#     assign :employers, [employer] 
#     render template: "general_agencies/profiles/_employers.html.erb" 
#   end

#   it 'should have title' do
#     expect(rendered).to have_selector('h3', text: 'Employers')
#   end

#   it 'should show general_agencies fields' do
#     expect(rendered).to have_selector('th', text: 'Legal Name')
#     expect(rendered).to have_selector('th', text: 'HBX Acct')
#     expect(rendered).to have_selector('th', text: 'Broker Agency Name')
#   end

#   it 'should show employer info' do
#     expect(rendered).to have_selector('a', text: "#{employer.legal_name}")
#     expect(rendered).to have_selector('td', text: "#{employer.hbx_id}")
#   end

#   it "should show broker_agency name" do
#     expect(rendered).to have_selector('td', text: "#{broker_agency_profile.legal_name}")
#   end
# end

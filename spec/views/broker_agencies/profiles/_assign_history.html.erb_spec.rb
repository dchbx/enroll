require 'rails_helper'

RSpec.describe "broker_agencies/profiles/_assign_history.html.erb", dbclean: :after_each do
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }

  before :each do
    FactoryGirl.create(:general_agency_account)
    assign :general_agency_account_history, Kaminari.paginate_array(GeneralAgencyAccount.all).page(0)
    assign :broker_agency_profile, broker_agency_profile
    render template: "broker_agencies/profiles/_assign_history.html.erb" 
  end

  it 'should have title' do
    expect(rendered).to have_selector('h2', text: 'Assign History')
  end

  it "should have content" do
    expect(rendered).to have_content('general_agency')
    expect(rendered).to have_content('Employer')
    expect(rendered).to have_content('Broker')
  end
end

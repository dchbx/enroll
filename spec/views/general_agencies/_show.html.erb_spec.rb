require 'rails_helper'

RSpec.describe "general_agencies/profiles/_show.html.erb", dbclean: :after_each do
  let(:general_agency_profile) {FactoryGirl.create(:general_agency_profile)}
  let(:user) {FactoryGirl.create(:user, :general_agency_staff)}
  let(:person) {FactoryGirl.create(:person)}
  before :each do
    sign_in user
    assign(:general_agency_profile, general_agency_profile)
    user.person = person
    user.save
    render template: "general_agencies/profiles/_show.html.erb"
  end

  it 'should have title' do
    expect(rendered).to have_selector('h3', text: 'General Agency')
  end

  it "should have status bar" do
    expect(rendered).to have_content('Edit General Agency')
  end
end
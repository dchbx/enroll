require "rails_helper"

RSpec.describe "broker_agencies/profiles/staff_table.html.erb" do
  let(:organization) { FactoryGirl.create(:organization) }
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }
  let(:broker_role1) { FactoryGirl.create(:broker_role, market_kind:'both', broker_agency_profile_id: broker_agency_profile.id) }
  let(:broker_role2) { FactoryGirl.create(:broker_role,  market_kind:'both', broker_agency_profile_id: broker_agency_profile.id)}
  let(:person1) {FactoryGirl.create(:person)}
  let(:person2) {FactoryGirl.create(:person)}
  before :each do
    allow(person1).to receive(:broker_role).and_return(broker_role1)
    allow(person2).to receive(:broker_role).and_return(broker_role2)
    assign :broker_agency_profile, broker_agency_profile
    assign :staff, [person1, person2]
    render template: "broker_agencies/profiles/_staff_table.html.erb"
  end

  it "should offer have Help" do
    expect(rendered).to have_selector('.broker_select_button', text: 'Select')
    expect(rendered).to have_selector('td', text: person1.full_name)
  end
end

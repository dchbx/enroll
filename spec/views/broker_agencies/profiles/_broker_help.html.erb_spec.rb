require "rails_helper"

RSpec.describe "broker_agencies/profiles/_broker_help_table.html.erb", dbclean: :after_each do
  let(:organization) { FactoryGirl.create(:organization) }
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization) }
  let(:broker_role1) { FactoryGirl.create(:broker_role, broker_agency_profile_id: broker_agency_profile.id) }
  let(:person1) {FactoryGirl.create(:person)}
  let(:email) {FactoryGirl.build(:email)}

  before :each do
    allow(person1).to receive(:broker_role).and_return(broker_role1)
    allow(broker_role1).to receive(:email).and_return(email)
    allow(broker_role1).to receive(:phone).and_return('7035551212')
    @broker = broker_role1
    @staff = person1
    render template: "broker_agencies/profiles/_broker_help.html.erb"
  end

  it "should be able to Select Broker" do
    expect(rendered).to have_selector('button', text: 'Select this Broker')
  end
  it "should show Broker Agency name" do
    expect(rendered).to have_selector('.tt-u', text: broker_agency_profile.legal_name)
  end
  it "should show change  Broker warning" do
    expect(rendered).to match(/Warning: if you already have an existing/)
  end
  it "show should the Broker email" do
    expect(rendered).to match(email.address)
  end
  it "show should the Broker phone" do
    expect(rendered).to match(broker_role1.phone)
  end

end

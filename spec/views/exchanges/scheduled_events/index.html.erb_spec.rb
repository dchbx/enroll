require 'rails_helper'
describe "exchanges/scheduled_events/index.html.erb" do
  let(:person) { FactoryBot.create(:person) }
  let(:user) { FactoryBot.create(:user, :person => person) }
  let(:scheduled_event) { FactoryBot.create(:scheduled_event) }
  let(:policy_obj) do
    double("Policy",
           view_admin_tabs?: true,
           access_outstanding_verification_sub_tab?: true,
           access_identity_verification_sub_tab?: true,
           view_the_configuration_tab?: true,
           can_access_user_account_tab?: true,
           begin_resident_enrollment?: true,
           access_new_consumer_application_sub_tab?: true,
           can_send_secure_message?: true,
           can_manage_qles?: true)
  end
  before :each do
    assign(:scheduled_event, scheduled_event)
    allow(view).to receive(:policy_helper).and_return(policy_obj)
    sign_in user
    @calendar_events = [FactoryBot.create(:scheduled_event)]
    @scheduled_events = [FactoryBot.create(:scheduled_event)]
  end

  it "should display index page info" do
    render template: "exchanges/scheduled_events/index"
    expect(rendered).to have_text(/Calendar/)
    expect(rendered).to have_text(/Previous/)
    expect(rendered).to have_text(/Next/)
    expect(rendered).to have_text(/Create Event/)
    expect(rendered).to have_text(/Mon/)
    expect(rendered).to have_text(/Tue/)
    expect(rendered).to have_text(/Wed/)
    expect(rendered).to have_text(/Thu/)
    expect(rendered).to have_text(/Fri/)
    expect(rendered).to have_text(/Sat/)
    expect(rendered).to have_text(/Sun/)
  end
end

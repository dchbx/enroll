require 'rails_helper'

describe "exchanges/scheduled_events/new.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, :person => person) }
  let(:scheduled_event) { ScheduledEvent.new }

  before :each do
  	assign(:scheduled_event, scheduled_event)
  	allow(view).to receive(:policy_helper).and_return(double("Policy", view_admin_tabs?: true))
    sign_in user
  end

  it "should display new page info" do
    def view.scheduled_event
      @scheduled_event ||= ScheduledEvent.find(params[:id])
    end
  	render template: "exchanges/scheduled_events/_new"
  	expect(rendered).to have_text(/Create Scheduled Events/)
    expect(rendered).to have_text(/Start time/)
    expect(rendered).to have_text(/Recurring rules/)
    expect(rendered).to have_text(/Offset rule/)
    expect(rendered).to have_text(/Cancel/)
  end
end

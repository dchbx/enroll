require 'rails_helper'
describe "exchanges/scheduled_events/show.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, :person => person) }
  let(:scheduled_event) { FactoryGirl.create(:scheduled_event) }
  before :each do
  	assign(:scheduled_event, scheduled_event)
  	allow(view).to receive(:policy_helper).and_return(double("Policy", view_admin_tabs?: true))
    sign_in user
  end

  it "should display show page info" do
    def view.scheduled_event
      @scheduled_event ||= ScheduledEvent.find(params[:id])
    end
  	render template: "exchanges/scheduled_events/_edit.html.erb"
    expect(rendered).to have_text(/Holiday/)
    expect(rendered).to have_text(/Offset rule/)
  end
end

require 'rails_helper'

describe "exchanges/announcements/_list.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, :person => person) }
  let(:announcement) { FactoryGirl.create(:announcement) }
  before :each do
    sign_in user
    assign(:announcements, [announcement])
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", modify_admin_tabs?: true))
    render template: "exchanges/announcements/_list.html.erb"
  end

  it "display announcements table" do
    expect(rendered).to have_selector('table.table')
    expect(rendered).to have_text('Current Announcements')
    expect(rendered).to have_text('Msg Start Date')
    expect(rendered).to have_text('Msg End Date')
    expect(rendered).to have_text('Audience')
  end

  it "display detail of announcement" do
    expect(rendered).to have_text(/#{announcement.content}/)
  end
end    


require 'rails_helper'

describe "exchanges/announcements/index.html.erb" do
  let(:person) { FactoryGirl.create(:person)}
  let(:user) { FactoryGirl.create(:user, :person => person)}
  before :each do
    stub_template "exchanges/hbx_profiles/shared/_primary_nav.html.erb"  => 'nav_bar'
    sign_in user
    assign(:announcements, Announcement.current)
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", modify_admin_tabs?: true))
    render template: "exchanges/announcements/index.html.erb"
  end

  it "should display announcements area" do
    expect(rendered).to have_selector('div.announcements')
  end

  it "should display title" do
    expect(rendered).to have_selector('h1', text: 'Announcements')
  end

  it "should display filter button" do
    expect(rendered).to have_selector('a', text: 'Current')
    expect(rendered).to have_selector('a', text: 'All')
  end

  it "should display announcements table" do
    expect(rendered).to have_selector('table.table')
    expect(rendered).to have_text('Current Announcements')
    expect(rendered).to have_text('Msg Start Date')
    expect(rendered).to have_text('Msg End Date')
    expect(rendered).to have_text('Audience')
  end

  it "should display the form of announcement" do
    expect(rendered).to have_selector('form.form-horizontal')
  end
end


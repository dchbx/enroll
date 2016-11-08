require 'rails_helper'
describe "exchanges/announcements/_new_form.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, :person => person) }
  before :each do
    sign_in user
    allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", modify_admin_tabs?: true))
    render template: "exchanges/announcements/_new_form.html.erb"
  end

  it "should display the form of announcement" do
    expect(rendered).to have_selector('form.form-horizontal')
  end

  it "should display audience kinds" do
    Announcement::AUDIENCE_KINDS.each do |kind|
      expect(rendered).to have_text(/#{kind}/)
    end
  end

  it "should see fields of announcement" do
    expect(rendered).to have_text(/Announcement/)
    expect(rendered).to have_text(/Msg Start Date/)
    expect(rendered).to have_text(/Msg End Date/)
    expect(rendered).to have_text(/Audience/)
  end
end


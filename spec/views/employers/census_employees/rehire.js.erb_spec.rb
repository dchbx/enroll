require 'rails_helper'

describe "employers/census_employees/rehire.js.erb" do
  let(:user){ FactoryGirl.create(:user, roles: ["hbx_staff"]) }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }

  before :each do
    #TODOJF WTF?  JS file is executing something.  Try to comment out line 10
    allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: false))
    sign_in user
    assign(:employer_profile, employer_profile)
    assign(:census_employee, census_employee)
    assign(:rehiring_date, Date.today)
    render file: "employers/census_employees/rehire.js.erb"
  end

  it "should display notice" do
    expect(rendered).to match /Successfully rehired Census Employee. Please update benefit group/
  end
end

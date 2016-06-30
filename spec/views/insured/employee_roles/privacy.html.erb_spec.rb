require 'rails_helper'

RSpec.describe "insured/employee_roles/privacy.html.erb" do
  let(:person) {FactoryGirl.create(:person)}

  before :each do
    assign(:person, person)
    render template: "insured/employee_roles/privacy.html.erb"
  end

  it "should display the employee privacy message" do
    expect(rendered).to have_selector('h1', text: 'Your Information')
    expect(rendered).to have_selector("strong", text: 'Please read the information below and click the')
    expect(rendered).to match(/Your answers on this application will only be/i)
    expect(rendered).to have_selector('.btn', text: 'CONTINUE')
  end
end

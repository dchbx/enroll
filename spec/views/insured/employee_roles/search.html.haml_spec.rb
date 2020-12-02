require 'rails_helper'

RSpec.describe "insured/employee_roles/search.html.haml" do
  let(:person) {FactoryBot.create(:person)}

  before :each do
    assign(:person, person)
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true))
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", can_access_progress?: true))
    render template: "insured/employee_roles/search.html.slim"
  end

  it "should display the employee search page" do
    expect(rendered).to have_selector('h3', text: 'Personal Information')
    expect(rendered).to have_selector("input[type='text']", count: 5)
    expect(rendered).to have_selector("input[type='radio']", count: 2)
  end
end

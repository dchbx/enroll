require 'rails_helper'

RSpec.describe "insured/employee_roles/no_match.html.haml" do
  let(:person) {FactoryGirl.create(:person)}


  before :each do
    assign(:person, person)
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true))
    render template: "insured/employee_roles/no_match.html.haml"
  end

  it "should display the employee search page with no match info" do
    expect(rendered).to have_selector('h1', text: 'Personal Information')
    expect(rendered).to have_selector("input[type='text']", count: 5)
    expect(rendered).to have_selector("input[type='radio']", count: 2)

    expect(rendered).to have_selector('strong', text: 'No employer found.')
    expect(rendered).to have_selector('div', text: "Please check the information entered above and confirm with your employer that your demographic information is listed correctly on their roster. For further assistance, please contact #{Settings.contact_center.name}: #{Settings.contact_center.phone_number}.")
  end
end

require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_census_employees.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee) { FactoryGirl.create(:census_employee) }

  before :each do
    allow(employer_profile).to receive(:census_employees).and_return [census_employee]
    assign(:employer_profile, employer_profile)
    assign(:avaliable_employee_names, "employee_names")
    assign(:datatable, Effective::Datatables::EmployeeDatatable.new({id: employer_profile.id}))
    
    assign(:census_employees, [])
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
    allow(view).to receive(:generate_checkbook_urls_employers_employer_profile_path).and_return('/')
    render "employers/employer_profiles/my_account/census_employees"
  end

  it "should display title" do
    expect(rendered).to match(/Employee Roster/)
  end

  it "should not have waive filter option" do
    expect(rendered).not_to have_selector("input[value='waived']")
  end

  it "should have the link of add employee" do
    expect(rendered).to have_selector("a", text: 'Add New Employee')
  end

  it "should have tab of cobra" do
    expect(rendered).to match(/COBRA only/)
  end
end

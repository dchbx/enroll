require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_census_employees.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee) { FactoryGirl.create(:census_employee) }
  # Person necessary for has_role? to work
  let(:user_with_hbx_staff_role) { FactoryGirl.create(:user, :with_family, :with_hbx_staff_role) }
  let(:user_with_employer_role) {FactoryGirl.create(:user, :employer_staff) }

  before :each do
    allow(employer_profile).to receive(:census_employees).and_return [census_employee]
    assign(:employer_profile, employer_profile)
    assign(:avaliable_employee_names, "employee_names")
    assign(:census_employees, [])
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
    allow(view).to receive(:generate_checkbook_urls_employers_employer_profile_path).and_return('/')
    allow(view).to receive(:current_user).and_return(user_with_employer_role)
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
    expect(rendered).to match(/COBRA Continuation/)
    expect(rendered).to have_selector('input#cobra')
  end

  context 'Terminate All Employees button' do
    it 'should display for HBX admin' do
      allow(view).to receive(:current_user).and_return(user_with_hbx_staff_role)
      render "employers/employer_profiles/my_account/census_employees"
      expect(rendered).to match(/Terminate Employee Roster Enrollments/)
    end

    it 'should not display for employer' do
      allow(view).to receive(:current_user).and_return(user_with_employer_role)
      render "employers/employer_profiles/my_account/census_employees"
      expect(rendered).to_not match(/Terminate Employee Roster Enrollments/)
    end
  end
end

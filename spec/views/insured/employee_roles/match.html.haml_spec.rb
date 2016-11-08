require 'rails_helper'

RSpec.describe "insured/employee_roles/match.html.haml" do
  let(:person) {FactoryGirl.create(:person)}
  let(:user) {FactoryGirl.create(:user, :person=>person)}
  let(:person_params){{"dob"=>person.id, "first_name"=>person.first_name,"gender"=>person.gender,"last_name"=>person.last_name,"middle_name"=>"","name_sfx"=>"","ssn"=>person.ssn,"user_id"=>person.id}}

  before :each do
    assign(:person, person)
    assign(:person_params, person_params)
    @employee_candidate = Forms::EmployeeCandidate.new(user_id: person.id)
    found_census_employees = @employee_candidate.match_census_employees
    @employment_relationships = Factories::EmploymentRelationshipFactory.build(@employee_candidate, found_census_employees.first)
    sign_in user
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true))
    render template: "insured/employee_roles/match.html.haml"
  end

  it "should display the employee search page with no match info" do

    expect(rendered).to have_selector('h1', text: 'Personal Information')
    expect(rendered).to have_selector("input[type='text']", count: 5)
    expect(rendered).to have_selector("input[type='radio']", count: 3)

    # expect(rendered).to have_selector("input[type=submit][value='This is my employer']")
    # expect(rendered).to have_selector('dt', text: 'Employer :')
    # expect(rendered).to have_selector("input", value: 'This is my employer')
    # expect(rendered).to have_selector('div', text: "Check your personal information and try again OR contact #{Settings.site.short_name}'s Customer Care Center: 1-855-532-5465.")
  end
end

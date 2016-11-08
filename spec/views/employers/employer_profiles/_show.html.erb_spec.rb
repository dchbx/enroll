require "rails_helper"

RSpec.describe "employers/employer_profiles/_show_profile" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: 'published') }
  let(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }
  let(:plan) { FactoryGirl.create(:plan) }
  let(:census_employee1) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee2) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee3) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:user) { FactoryGirl.create(:user) }

  before :each do
    @employer_profile = employer_profile
    assign(:census_employees, [census_employee1, census_employee2, census_employee3])
    assign(:plan_year, plan_year)
    @current_plan_year = plan_year
    sign_in user
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true, list_enrollments?: true))
  end

  it "should display the dashboard content" do
    @tab = 'home'
    render template: "employers/employer_profiles/show"
    expect(rendered).to have_selector('h1', text: 'My Health Benefits Program')
  end

  it "should display premium billing reports widget" do
    @tab = 'home'
    render template: "employers/employer_profiles/show"
    expect(rendered).to have_selector('h3', text: 'Enrollment Report')
  end

  it "shouldn't display premium billing reports widget" do
    @tab = 'home'
    allow(plan_year).to receive(:aasm_state).and_return("renewing_draft")
    render template: "employers/employer_profiles/show"
    expect(rendered).to_not have_selector('h3', text: 'Enrollment Report')
  end

  it "should have active plan year but not display premium billings report" do
    allow(plan_year).to receive(:start_on).and_return(TimeKeeper.date_of_record + 3.years)
    @tab = 'home'
    render template: "employers/employer_profiles/show"
    y = TimeKeeper.date_of_record + 3.years
    year = y.year
    expect(rendered).to_not have_selector('h3', text: 'Enrollment Report')
  end

end

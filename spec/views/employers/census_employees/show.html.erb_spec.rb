require "rails_helper"

RSpec.describe "employers/census_employees/show.html.erb" do
  let(:plan){ FactoryGirl.create(:plan) }
  let(:family){ FactoryGirl.create(:family, :with_primary_family_member) }
  let(:household){ FactoryGirl.create(:household, family: family) }
  let(:person){ Person.new(first_name: "first name", last_name: "last_name", dob: 20.years.ago) }
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:plan_year){ FactoryGirl.create(:plan_year) }
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:relationship_benefit){ RelationshipBenefit.new(relationship: "employee") }
  let(:benefit_group) {BenefitGroup.new(title: "plan name", relationship_benefits: [relationship_benefit], dental_relationship_benefits: [relationship_benefit], plan_year: plan_year )}
  let(:benefit_group_assignment) { BenefitGroupAssignment.new(benefit_group: benefit_group) }
  let(:reference_plan){ double("Reference Plan") }
  let(:address){ Address.new(kind: 'home', address_1: "1111 spalding ct", address_2: "apt 444", city: "atlanta", state: "ga", zip: "30338") }
  let(:hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  # let(:hbx_enrollment) {double("HbxEnrollment1",waiver_reason: "this is reason", plan: double(name: "hbx enrollment plan name"), hbx_enrollment_members: [hbx_enrollment_member], coverage_kind: 'health')}
  let(:hbx_enrollment){ FactoryGirl.create(:hbx_enrollment,
    household: household,
    plan: plan,
    benefit_group: benefit_group,
    hbx_enrollment_members: [hbx_enrollment_member],
    coverage_kind: "health")
    # external_enrollment: false )
  }
  let(:hbx_enrollment_two){ FactoryGirl.create(:hbx_enrollment,
    household: household,
    plan: plan,
    benefit_group: benefit_group,
    hbx_enrollment_members: [hbx_enrollment_member],
    coverage_kind: "dental")
    # external_enrollment: false )
  }
  # let(:hbx_enrollment_two) {double("HbxEnrollment2",waiver_reason: "this is reason", plan: double(name: "hbx enrollment plan name"), hbx_enrollment_members: [hbx_enrollment_member], coverage_kind: 'dental')}
  # let(:plan) {double(total_premium: 10, total_employer_contribution: 20, total_employee_cost:30)}
  let(:decorated_hbx_enrollment) { PlanCostDecorator.new(plan, hbx_enrollment, benefit_group, hbx_enrollment.plan) }
  let(:user) { FactoryGirl.create(:user) }

  before(:each) do
    sign_in user
    assign(:employer_profile, employer_profile)
    assign(:census_employee, census_employee)
    assign(:benefit_group_assignment, benefit_group_assignment)
    assign(:hbx_enrollment, hbx_enrollment)
    assign(:hbx_enrollments, [hbx_enrollment])
    assign(:benefit_group, benefit_group)
    assign(:plan, plan)
    assign(:active_benefit_group_assignment, benefit_group_assignment)
    allow(hbx_enrollment_member).to receive(:person).and_return(person)
    allow(hbx_enrollment_member).to receive(:primary_relationship).and_return("self")
    allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
    allow(hbx_enrollment).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
    allow(hbx_enrollment).to receive(:total_premium).and_return(hbx_enrollment)
    allow(hbx_enrollment).to receive(:total_employer_contribution).and_return(hbx_enrollment)
    allow(hbx_enrollment).to receive(:total_employee_cost).and_return(hbx_enrollment)
    allow(view).to receive(:policy_helper).and_return(double('EmployerProfile', updateable?: true, list_enrollments?: true))
  end

  it "should show the address of census employee" do
    allow(census_employee).to receive(:address).and_return(address)
    render template: "employers/census_employees/show.html.erb"
    expect(rendered).to match /#{address.address_1}/
    expect(rendered).to match /#{address.address_2}/
    expect(rendered).to match /#{address.city}/
    expect(rendered).to match /#{address.state}/i
    expect(rendered).to match /#{address.zip}/
  end

  it "should not show the plan" do
    allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([])
    assign(:hbx_enrollments, [])
    render template: "employers/census_employees/show.html.erb"
    expect(rendered).to_not match /Plan/
    expect(rendered).to_not have_selector('p', text: 'Benefit Group: plan name')
  end

  it "should show waiver" do
    hbx_enrollment.update_attributes(:aasm_state => 'inactive', )
    allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
    allow(hbx_enrollment).to receive(:plan).and_return(nil)
    render template: "employers/census_employees/show.html.erb"
    expect(rendered).to match /Waived Date/i
    expect(rendered).to match /#{hbx_enrollment.waiver_reason}/
  end

  it "should show plan name" do
    allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
    render template: "employers/census_employees/show.html.erb"
    expect(rendered).to match /#{hbx_enrollment.plan.name}/
  end

  # it "should not show the health plan if it is external enrollment" do
  #   hbx_enrollment.update_attributes(:external_enrollment => true, coverage_kind: "health")
  #   allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
  #   render template: "employers/census_employees/show.html.erb"
  #   expect(rendered).to_not match /Plan/
  #   expect(rendered).to_not have_selector('p', text: 'Benefit Group: plan name')
  # end

  # it "should not show the dental plan if it is external enrollment" do
  #   hbx_enrollment.update_attributes(:external_enrollment => true, coverage_kind: "dental" )
  #   allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
  #   render template: "employers/census_employees/show.html.erb"
  #   expect(rendered).to_not match /Plan/
  #   expect(rendered).to_not have_selector('p', text: 'Benefit Group: plan name')
  # end

  it "should show plan cost" do
    allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
    render template: "employers/census_employees/show.html.erb"
    expect(rendered).to match /Employer Contribution/
    expect(rendered).to match /You Pay/
  end

  context 'with a previous coverage waiver' do
    let(:hbx_enrollment_three) do
      FactoryGirl.create :hbx_enrollment, household: household,
        plan: plan,
        benefit_group: benefit_group,
        hbx_enrollment_members: [ hbx_enrollment_member ],
        coverage_kind: 'dental',
        original_application_type: "phil wins"
    end

    before do
      allow(benefit_group).to receive(:dental_reference_plan).and_return(hbx_enrollment_three.plan)
      hbx_enrollment_two.update_attributes(:aasm_state => :inactive)
      assign(:hbx_enrollments, [hbx_enrollment_three, hbx_enrollment_two])
      render template: 'employers/census_employees/show.html.erb'
    end

    it "doesn't show the waived coverage" do
      expect(rendered).to_not match(/Waiver Reason/)
    end
  end

  context "dependents" do
    let(:census_dependent1) {double('CensusDependent1', persisted?: true, _destroy: true, valid?: true, relationship: 'child_under_26', first_name: 'jack', last_name: 'White', middle_name: 'bob', ssn: 123123123, dob: Date.today, gender: 'male', employee_relationship: 'child_under_26', id: 1231623)}
    let(:census_dependent2) {double('CensusDependent2', persisted?: true, _destroy: true, valid?: true, relationship: 'child_26_and_over', first_name: 'jack', last_name: 'White', middle_name: 'bob', ssn: 123123123, dob: Date.today, gender: 'male', employee_relationship: 'child_26_and_over', id: 1231223)}
    before :each do
      allow(benefit_group_assignment).to receive(:hbx_enrollment).and_return(hbx_enrollment)
    end

    it "should get dependents title" do
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to match /Dependents/
    end

    it "should get child relationship when child_under_26" do
      allow(view).to receive(:link_to_add_fields).and_return(true)
      allow(census_employee).to receive(:census_dependents).and_return([census_dependent1])
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to match /child/
    end

    it "should get the Owner info" do
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to match /Owner?/i
    end

  end

  context 'with coverage_terminated_on present' do

    before do
      allow(census_employee).to receive(:aasm_state).and_return("employment_terminated")
      render template: 'employers/census_employees/show.html.erb'
    end

    it "doesn't show the waived coverage" do
      expect(rendered).to match(/Employment Terminated/i)
    end
  end

end

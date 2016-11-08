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
    coverage_kind: "health",
    external_enrollment: false )
  }
  let(:hbx_enrollment_two){ FactoryGirl.create(:hbx_enrollment,
    household: household,
    plan: plan,
    benefit_group: benefit_group,
    hbx_enrollment_members: [hbx_enrollment_member],
    coverage_kind: "dental",
    external_enrollment: false )
  }
  # let(:hbx_enrollment_two) {double("HbxEnrollment2",waiver_reason: "this is reason", plan: double(name: "hbx enrollment plan name"), hbx_enrollment_members: [hbx_enrollment_member], coverage_kind: 'dental')}
  # let(:plan) {double(total_premium: 10, total_employer_contribution: 20, total_employee_cost:30)}
  let(:decorated_hbx_enrollment) { PlanCostDecorator.new(plan, hbx_enrollment, benefit_group, hbx_enrollment.plan) }
  let(:user) { FactoryGirl.create(:user) }

  before(:each) do
    sign_in user
    allow(view).to receive(:policy_helper).and_return(double("EmployerProfilePolicy", updateable?: true, list_enrollments?: true))
    assign(:employer_profile, employer_profile)
    assign(:census_employee, census_employee)
    assign(:benefit_group_assignment, benefit_group_assignment)
    assign(:hbx_enrollment, hbx_enrollment)
    assign(:hbx_enrollments, [hbx_enrollment])
    assign(:benefit_group, benefit_group)
    assign(:plan, plan)
    assign(:status, "terminated")
    assign(:active_benefit_group_assignment, benefit_group_assignment)
    allow(hbx_enrollment_member).to receive(:person).and_return(person)
    allow(hbx_enrollment_member).to receive(:primary_relationship).and_return("self")
    allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
    allow(hbx_enrollment).to receive(:decorated_hbx_enrollment).and_return(decorated_hbx_enrollment)
    allow(hbx_enrollment).to receive(:total_premium).and_return(hbx_enrollment)
    allow(hbx_enrollment).to receive(:total_employer_contribution).and_return(hbx_enrollment)
    allow(hbx_enrollment).to receive(:total_employee_cost).and_return(hbx_enrollment)
    allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
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

  it "should show the address feild of census employee if address not present" do
    allow(census_employee).to receive(:address).and_return([])
    render template: "employers/census_employees/show.html.erb"
    expect(rendered).to match /Address/
    expect(rendered).to match /ADDRESS LINE 2/
    expect(rendered).to match /ADDRESS LINE 1/
    expect(rendered).to match /CITY/
    expect(rendered).to match /SELECT STATE/
    expect(rendered).to match /ZIP/
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

  it "should show plan cost" do
    allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
    render template: "employers/census_employees/show.html.erb"
    expect(rendered).to match /Employer Contribution/
    expect(rendered).to match /You Pay/
  end

  it "should not show the health enrollment if it is external" do
    hbx_enrollment.update_attributes(:external_enrollment => true)
    allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment])
    render template: "employers/census_employees/show.html.erb"
    expect(rendered).to_not match /Plan/
    expect(rendered).to_not have_selector('p', text: 'Benefit Group: plan name')
  end

  it "should not show the dental enrollment if it is external" do
    hbx_enrollment_two.update_attributes(:external_enrollment => true)
    allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([hbx_enrollment_two])
    render template: "employers/census_employees/show.html.erb"
    expect(rendered).to_not match /Plan/
    expect(rendered).to_not have_selector('p', text: 'Benefit Group: plan name')
  end

  context  'drop down menu at different cases' do
    it "should have BENEFIT PACKAGE and benefit plan" do
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to have_selector('div', text: 'SELECT BENEFIT PACKAGE')
      expect(rendered).to have_selector('div', text: benefit_group.title)
    end
    context "when both ee and er have no benefit group assignment" do
      #to make sure census_employee.benefit_group_assignments.last
      let(:census_employee) { CensusEmployee.new(first_name: "xz", last_name: "yz")}
      before do
        # to make sure census_employee.active_benefit_group_assignment = nil
        allow(census_employee).to receive(:active_benefit_group_assignment).and_return(nil)
      end
      it "should only have BENIFIT PACKAGE" do
        render template: "employers/census_employees/show.html.erb"
        expect(rendered).to have_selector('div', text: 'SELECT BENEFIT PACKAGE')
        expect(rendered).to_not have_selector('div', text: benefit_group.title)
      end
    end
   end

  context 'with no email linked with census employee' do
    let(:census_employee) { CensusEmployee.new(first_name: "xz", last_name: "yz")}
    it "should create a blank email record if there was no email for census employees" do
      expect(census_employee.email).to eq nil
      render template: "employers/census_employees/show.html.erb"
      expect(census_employee.email).not_to eq nil
      expect(census_employee.email.kind).to eq nil
      expect(census_employee.email.address).to eq nil
    end

    it "should return the existing one if email was already present" do
      census_employee = FactoryGirl.create(:census_employee)
      address = census_employee.email.address
      render template: "employers/census_employees/show.html.erb"
      expect(census_employee.email.kind).to eq 'home'
      expect(census_employee.email.address).to eq address
    end
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

  context "with health, dental, and past enrollments" do
    let(:dental_plan){ FactoryGirl.create(:plan,
      name: "Some plan name",
      carrier_profile_id: carrier_profile._id,
      active_year: TimeKeeper.date_of_record.year,
      metal_level: "dental",
      dental_level: "high",
      coverage_kind: 'dental'
    )}
    let(:dental_hbx_enrollment){ FactoryGirl.create(:hbx_enrollment,
      household: household,
      plan: dental_plan,
      benefit_group: benefit_group,
      coverage_kind: 'dental'
    )}
    let(:carrier_profile) { FactoryGirl.build_stubbed(:carrier_profile) }
    let(:past_enrollments) { FactoryGirl.build_stubbed(:hbx_enrollment, aasm_state: 'coverage_terminated' ) }
    before :each do
      assign(:past_enrollments, [past_enrollments])
      allow(census_employee).to receive_message_chain("active_benefit_group_assignment.hbx_enrollments").and_return([hbx_enrollment, dental_hbx_enrollment])
    end

    it "should display past enrollments" do
      render template: "employers/census_employees/show.html.erb"
      expect(rendered).to match /#{hbx_enrollment.coverage_year} health Coverage/i
      expect(rendered).to match /#{hbx_enrollment.coverage_year} dental Coverage/i
      expect(rendered).to match /Past Enrollments/i
    end

    context "with not health, but dental and past enrollments" do
      before :each do
        allow(census_employee).to receive_message_chain("active_benefit_group_assignment.hbx_enrollments").and_return([dental_hbx_enrollment])
      end
      it "should display past enrollments" do
        render template: "employers/census_employees/show.html.erb"
        expect(rendered).not_to match /#{hbx_enrollment.coverage_year} health Coverage/i
        expect(rendered).to match /#{hbx_enrollment.coverage_year} dental Coverage/i
        expect(rendered).to match /Past Enrollments/i
      end
    end

    context "with health and dental, but no past enrollments" do
      before :each do
        assign(:past_enrollments, [])
        allow(census_employee).to receive_message_chain("active_benefit_group_assignment.hbx_enrollments").and_return([hbx_enrollment, dental_hbx_enrollment])
      end
      it "should display past enrollments" do
        render template: "employers/census_employees/show.html.erb"
        expect(rendered).to match /#{hbx_enrollment.coverage_year} health Coverage/i
        expect(rendered).to match /#{hbx_enrollment.coverage_year} dental Coverage/i
        expect(rendered).not_to match /Past Enrollments/i
      end
    end
  end
end

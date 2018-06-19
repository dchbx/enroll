require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_employees_by_status.html.erb", dbclean: :before_each do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:census_employee1) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee2) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:census_employee3) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let!(:census_employees) { [census_employee1, census_employee2, census_employee3] }

  let(:person) { FactoryGirl.create(:person) }
  let(:employee_role) { FactoryGirl.create(:employee_role, person: person) }
  let(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: primary_family.active_household)}

  let(:user) { FactoryGirl.create(:user) }

  let(:benefit_group) { BenefitGroup.new }

  let(:benefit_group_assignment1) { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee1) }
  let(:benefit_group_assignment3) { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee3, aasm_state: "coverage_waived") }

  let(:benefit_group_assignment2) { FactoryGirl.create(:benefit_group_assignment, census_employee: census_employee2, aasm_state: "coverage_terminated") }
  let!(:enrollment_with_coverage_selected)   { FactoryGirl.create( :hbx_enrollment,
    household: primary_family.latest_household,
    employee_role_id: employee_role.id,
    benefit_group_assignment: benefit_group_assignment1
    )}
  let!(:enrollment_with_coverage_terminated)   { FactoryGirl.create( :hbx_enrollment,
    household: primary_family.latest_household,
    employee_role_id: employee_role.id,
    benefit_group_assignment: benefit_group_assignment2,
    aasm_state: "coverage_terminated"
    )}

  let!(:enrollment_with_coverage_waived)   { FactoryGirl.create( :hbx_enrollment,
    household: primary_family.latest_household,
    employee_role_id: employee_role.id,
    benefit_group_assignment: benefit_group_assignment3,
    aasm_state: "inactive"
    )}

  before :each do
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true, revert_application?: true))
    allow(EmployerProfile).to receive(:find).and_return(employer_profile)

    sign_in(user)
    assign(:employer_profile, employer_profile)
    assign(:employees, census_employees)
    assign(:datatable, Effective::Datatables::EmployeeDatatable.new({id: employer_profile.id}))
    assign(:page_alphabets, ['a', 'b', 'c'])
    sign_in user
    stub_template "shared/alph_paginate" => ''
  end

  context 'when employee has active coverage' do
    it "should displays enrollment state when coverage selected" do
    #  assign(:census_employees, [census_employee1])
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      expect(rendered).to match(/Enrolled/)
    end
  end

  context 'when employee coverage terminated' do
    before do
      allow(census_employee2).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment2)
      allow(census_employee2).to receive(:aasm_state).and_return 'employment_terminated'
      allow(census_employee2).to receive(:can_elect_cobra?).and_return true
      allow(census_employee2).to receive(:employment_terminated_on).and_return TimeKeeper.date_of_record
    end

    it "should displays enrollment state as coverage terminated" do
      assign(:census_employees, [census_employee2])
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      expect(rendered).to match(/Terminated/)
    end

    it "should displays rehire function" do
      assign(:census_employees, [census_employee2])
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      expect(rendered).to match(/Rehire/)
    end

    it "should displays cobra function" do
      assign(:census_employees, [census_employee2])
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      expect(rendered).to match(/Initiate Cobra/)
    end

    # it "should displays cobra confirm area" do
    #   assign(:census_employees, [census_employee2])
    #   render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
    #   expect(rendered).to have_selector('tr.cobra_confirm')
    #   expect(rendered).to match(/Initiate Cobra/)
    # end

    # it "should displays termination date when status is all" do
    #   assign(:census_employees, [census_employee2])
    #   render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
    #   expect(rendered).to have_content('Termination Date')
    # end

    # it "should displays termination date when status is terminated" do
    #   assign(:census_employees, [census_employee2])
    #   render "employers/employer_profiles/my_account/employees_by_status", :status => "terminated"
    #   expect(rendered).to have_content('Termination Date')
    # end
  end

  context 'when employee is waived' do
    it "should displays enrollment status as waived" do
      assign(:census_employees, [census_employee3])
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      expect(rendered).to match(/Waived/)
    end
  end

  context 'Search' do
    before do
      allow(census_employee1).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment1)
      allow(census_employee2).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment2)
      allow(census_employee3).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment3)
      assign(:search, true)
    end

    it "should displays search result title" do
      assign(:census_employees, census_employees)
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      census_employees.each do |ce|
        expect(rendered).to match /.*#{ce.first_name}.*#{ce.last_name}.*/
      end
    end

    it "should displays no results found" do
      assign(:search, true)
      assign(:census_employees, [])
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      expect(rendered).to match /No results found/
    end
  end

  # context "renewal enrollment state" do
  #   let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile) }
  #   let(:benefit_group_assignment) { FactoryGirl.create( :benefit_group_assignment, census_employee: census_employee1 ) }
  #   let(:benefit_group) { FactoryGirl.create( :benefit_group, benefit_group_assignment: benefit_group_assignment ) }

  #   before do
  #     benefit_group_assignment.select_coverage
  #     allow(census_employee1).to receive(:renewal_benefit_group_assignment).and_return(benefit_group_assignment)
  #     allow(employer_profile).to receive(:renewing_published_plan_year).and_return(true)

  #   end

  #   it "should displays the renewal enrollment aasm state" do
  #     assign(:census_employees, [census_employee1])
  #     render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
  #     expect(rendered).to match(/Renewal Enrollment Status/)
  #   end
  # end

  context "enrolling enrollment state" do
    let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile) }
    let(:benefit_group_assignment) { FactoryGirl.create( :benefit_group_assignment, census_employee: census_employee1 ) }
    let(:benefit_group) { FactoryGirl.create( :benefit_group, benefit_group_assignment: benefit_group_assignment ) }

    before do
      benefit_group_assignment.select_coverage
      allow(census_employee1).to receive(:renewal_benefit_group_assignment).and_return(benefit_group_assignment)
      allow(employer_profile).to receive(:renewing_published_plan_year).and_return(false)
    end

    it "should displays the renewal enrollment aasm state" do
      assign(:census_employees, [census_employee1])
      render "employers/employer_profiles/my_account/employees_by_status", :status => "all"
      expect(rendered).to_not match(/Renewal Enrollment Status/)
      expect(rendered).to_not match(/#{benefit_group_assignment.aasm_state.humanize}/)
    end
  end


end

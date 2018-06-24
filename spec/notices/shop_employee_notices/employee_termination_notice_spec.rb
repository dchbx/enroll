require 'rails_helper'

RSpec.describe ShopEmployeeNotices::EmployeeTerminationNotice, :dbclean => :after_each do
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Employee Termination Notice',
                            :notice_template => 'notices/shop_employee_notices/employee_termination_notice',
                            :notice_builder => 'ShopEmployeeNotices::EmployeeTerminationNotice',
                            :mpi_indicator => 'MPI_DAG058',
                            :event_name => 'employee_termination_notice',
                            :title => "EE Ineligibility Notice – Terminated from Roster"})
                          }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id,
    employment_terminated_on:TimeKeeper.date_of_record.end_of_month,
    coverage_terminated_on:TimeKeeper.date_of_record.end_of_month) }
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group_id: active_benefit_group.id, census_employee: census_employee, start_on: start_on, is_active: true) }
  let(:family) {
      family = FactoryGirl.build(:family, :with_primary_family_member_and_dependent)
      primary_person = family.family_members.where(is_primary_applicant: true).first.person
      other_child_person1 = family.family_members.where(is_primary_applicant: false).first.person
      other_child_person2 = family.family_members.where(is_primary_applicant: false).last.person
      primary_person.person_relationships << PersonRelationship.new(relative_id: other_child_person1.id, kind: "child")
      primary_person.person_relationships << PersonRelationship.new(relative_id: other_child_person2.id, kind: "child")
      primary_person.save
      family.save
      family
    }

  let!(:enrollment) do
    hbx = FactoryGirl.create(:hbx_enrollment, household: family.active_household, coverage_kind: 'health', aasm_state:'coverage_termination_pending',benefit_group_assignment_id: benefit_group_assignment.id)
    hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true)
    hbx.save
    hbx
  end

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeTerminationNotice.new(census_employee, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::EmployeeTerminationNotice.new(census_employee, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployeeNotices::EmployeeTerminationNotice.new(census_employee, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeTerminationNotice.new(census_employee, valid_parmas)
    end
    it "should build notice with all necesesory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    before do
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return [enrollment]
      @employee_notice = ShopEmployeeNotices::EmployeeTerminationNotice.new(census_employee, valid_parmas)
      @employee_notice.append_data
    end

    it "should return employment terminated date" do
      expect(@employee_notice.census_employee.employment_terminated_on).to eq census_employee.employment_terminated_on
    end

    it "should return coverage terminated date" do
      expect(@employee_notice.census_employee.coverage_terminated_on).to eq census_employee.coverage_terminated_on
    end

    it "should return plan name" do
      expect(@employee_notice.notice.census_employee.enrollments.first.plan.plan_name).to eq enrollment.plan.name
    end

    it "should return coverage kind" do
      expect(@employee_notice.notice.census_employee.enrollments.first.plan.coverage_kind).to eq enrollment.coverage_kind
    end

    it "should return enrolled count" do
      expect(@employee_notice.notice.census_employee.enrollments.first.enrolled_count).to eq enrollment.humanized_dependent_summary.to_s
    end

  end

  describe "render template and generate pdf" do
    before do
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return [enrollment]
      @employee_notice = ShopEmployeeNotices::EmployeeTerminationNotice.new(census_employee, valid_parmas)
      @employee_notice.build
      @employee_notice.append_data
    end

    it "should render employee termination notice" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/employee_termination_notice"
    end

    it "should generate pdf" do
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end
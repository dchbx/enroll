require 'rails_helper'

RSpec.describe ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation do
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.month - 1.year }
  let!(:employer_profile) { create :employer_profile, aasm_state: "active" }
  let!(:person) { create :person }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'renewing_enrolled') }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_enrolled') }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let!(:employee_role) { FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
  let!(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let!(:renewal_plan) { FactoryGirl.create(:plan) }
  let!(:plan) { FactoryGirl.create(:plan, market: 'shop', metal_level: 'gold', hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id, coverage_kind: 'health') }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, benefit_group_assignment: benefit_group_assignment, benefit_group: renewal_benefit_group, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 2.month, plan: plan) }
  let!(:application_event) { double("ApplicationEventKind", {
    :name => 'Notify Employees Enrollment confirmation',
    :notice_template => 'notices/shop_employee_notices/renewal_employee_enrollment_confirmation',
    :notice_builder => 'ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation',
    :event_name => 'renewal_employee_enrollment_confirmation',
    :mpi_indicator => 'SHOP_D076',
    :title => "Employee Enrollment Confirmation"})
  }

  let!(:valid_params) { {
    :subject => application_event.title,
    :mpi_indicator => application_event.mpi_indicator,
    :event_name => application_event.event_name,
    :template => application_event.notice_template
  } }

  describe "New" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect { ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation.new(census_employee, valid_params) }.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator, :subject, :template].each do |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect { ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation.new(census_employee, valid_params) }.to raise_error(RuntimeError, "Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation.new(census_employee, valid_params)
    end

    it "should build notice with all necessory info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq census_employee.employer_profile.staff_roles.first.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    before do
      @employee_notice = ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation.new(census_employee, valid_params)
      allow(census_employee).to receive(:renewal_benefit_group_assignment).and_return benefit_group_assignment
    end
    it "should append data" do
      hbx_enrollment.update_attributes(benefit_group_assignment_id: benefit_group_assignment.id)
      enrollment = census_employee.renewal_benefit_group_assignment.hbx_enrollments.first
      @employee_notice.append_data
      @employee_notice.build
      expect(@employee_notice.notice.plan.plan_name).to eq plan.name
      expect(@employee_notice.notice.enrollment.employee_cost).to eq("0.0")
      expect(@employee_notice.notice.enrollment.effective_on).to eq hbx_enrollment.effective_on
    end
  end

  describe "render template and generate pdf" do
    before do
      @employee_notice = ShopEmployeeNotices::RenewalEmployeeEnrollmentConfirmation.new(census_employee, valid_params)
      allow(census_employee).to receive(:renewal_benefit_group_assignment).and_return benefit_group_assignment
      @employee_notice.build
      @employee_notice.append_data
      @employee_notice.generate_pdf_notice
    end

    it "should render renewal_employee_enrollment_confirmation" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/renewal_employee_enrollment_confirmation"
    end

    it "should generate pdf" do
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end

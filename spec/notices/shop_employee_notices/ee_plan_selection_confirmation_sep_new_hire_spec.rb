require 'rails_helper'

RSpec.describe ShopEmployeeNotices::EePlanConfirmationSepNewHire do
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.month - 1.year }
  let!(:employer_profile) { create :employer_profile, aasm_state: "active" }
  let!(:person) { create :person }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active') }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft') }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let!(:employee_role) { FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
  let!(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let!(:renewal_plan) { FactoryGirl.create(:plan) }
  let!(:plan) { FactoryGirl.create(:plan, :with_premium_tables, :renewal_plan_id => renewal_plan.id) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, benefit_group_assignment: benefit_group_assignment, benefit_group: benefit_group, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 2.month, plan: plan, aasm_state: 'coverage_termination_pending') }
  let!(:application_event) { double("ApplicationEventKind", {
    :name => 'Notification to employees regarding plan purchase during Open Enrollment or an SEP',
    :notice_template => 'notices/shop_employee_notices/ee_plan_selection_confirmation_sep_new_hire',
    :notice_builder => 'ShopEmployeeNotices::EePlanConfirmationSepNewHire',
    :event_name => 'ee_plan_selection_confirmation_sep_new_hire',
    :mpi_indicator => 'MPI_SHOPDAE074',
    :title => "Employee Plan Selection Confirmation"})
  }

  let!(:valid_params) { {
    :subject => application_event.title,
    :mpi_indicator => application_event.mpi_indicator,
    :event_name => application_event.event_name,
    :template => application_event.notice_template,
    :options => { :hbx_enrollment => hbx_enrollment.hbx_id.to_s }
  }}

  describe "New" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect { ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params) }.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator, :subject, :template].each do |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect { ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params) }.to raise_error(RuntimeError, "Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params)
    end

    it "should build notice with all necessory info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq census_employee.employer_profile.staff_roles.first.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    let(:enrollment) { hbx_enrollment }

    before do
      @employer_notice = ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      @employer_notice.deliver
    end

    it "should append data" do
      expect(@employer_notice.notice.enrollment.effective_on.to_s).to eq(enrollment.effective_on.to_s)
      expect(@employer_notice.notice.enrollment.plan.plan_name).to eq(plan.name)
      expect(@employer_notice.notice.enrollment.employee_cost).to eq("0.0")
      expect(@employer_notice.notice.enrollment.employer_contribution).to eq("0.0")
    end

    it "should render ee_plan_selection_notice" do
      expect(@employer_notice.template).to eq "notices/shop_employee_notices/ee_plan_selection_confirmation_sep_new_hire"
    end

    it "should generate pdf" do
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
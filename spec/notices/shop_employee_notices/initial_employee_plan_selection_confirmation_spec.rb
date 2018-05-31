require 'rails_helper'

RSpec.describe ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}  
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'enrolled' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group_id: active_benefit_group.id, census_employee: census_employee, start_on: active_benefit_group.start_on) }
  let(:application_event){ double("ApplicationEventKind",{
                            name: 'Notice to employee after they select a plan Annual Open Enrollment',
                            notice_template: 'notices/shop_employee_notices/initial_employee_plan_selection_confirmation',
                            notice_builder: 'ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation',
                            mpi_indicator: 'SHOP_M070',
                            event_name: 'initial_employee_plan_selection_confirmation',
                            title: "Employee Enrollment Confirmation"})
                          }

  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year, plan: plan)}  
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables)}   

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator, :subject, :template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation.new(census_employee, valid_params)
    end
    it "should build notice with all necessory info" do

      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    before do
      @employee_notice = ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation.new(census_employee, valid_params)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
    end
    it "should append data" do
      hbx_enrollment.update_attributes(benefit_group_assignment_id: benefit_group_assignment.id)
      census_employee.active_benefit_group_assignment.hbx_enrollments.first
      @employee_notice.append_data
      expect(@employee_notice.notice.plan_year.open_enrollment_start_on).to eq plan_year.open_enrollment_start_on
      expect(@employee_notice.notice.plan_year.open_enrollment_end_on).to eq plan_year.open_enrollment_end_on
      expect(@employee_notice.notice.plan_year.start_on).to eq plan_year.start_on
      expect(@employee_notice.notice.plan.plan_name).to eq plan.name
    end
  end

end
require 'rails_helper'

RSpec.describe ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}  
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'enrolling' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group_id: active_benefit_group.id, census_employee: census_employee, start_on: active_benefit_group.start_on) }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Notice to employee after they select a plan during Annual Open Enrollment',
                            :notice_template => 'notices/shop_employee_notices/employee_select_plan_during_open_enrollment',
                            :notice_builder => 'ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment',
                            :mpi_indicator => 'SHOP_D073',
                            :event_name => 'ee_select_plan_during_oe',
                            :title => "Employee Plan Selection Confirmation"})
                          }

  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year, plan: plan, benefit_group: active_benefit_group)}  
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables)}   

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => { :hbx_enrollment_hbx_id => hbx_enrollment.hbx_id.to_s }
  }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment.new(census_employee, valid_params)
    end

    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    before do
      @employee_notice = ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment.new(census_employee, valid_params)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      hbx_enrollment.update_attributes(benefit_group_assignment_id: benefit_group_assignment.id)
      enrollment = census_employee.active_benefit_group_assignment.hbx_enrollments.first
      @employee_notice.append_data
    end
    it "should append enrollment effective on date" do
      expect(@employee_notice.notice.enrollment.effective_on).to eq hbx_enrollment.effective_on
    end
    it "shoud append plan name" do
      expect(@employee_notice.notice.plan.plan_name).to eq plan.name
    end
    it "should append employee_cost" do
      expect(@employee_notice.notice.enrollment.employee_cost).to eq(hbx_enrollment.total_employee_cost.to_s)
    end
    it "should append employer_contribution" do
      expect(@employee_notice.notice.enrollment.employer_contribution).to eq(hbx_enrollment.total_employer_contribution.to_s)
    end
  end

  describe "Rendering Employee Plan Selection Confirmation template and generate pdf" do
    before do
      allow(census_employee).to receive_message_chain("employee_role.person").and_return(person)
      allow(census_employee).to receive(:employer_profile).and_return(employer_profile)
      @employee_notice = ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment.new(census_employee, valid_params)
      allow(census_employee.active_benefit_group_assignment).to receive(:hbx_enrollment).and_return hbx_enrollment
    end
    it "should render employee_select_plan_during_open_enrollment" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/employee_select_plan_during_open_enrollment"
    end
    it "should render event" do
      expect(@employee_notice.event_name).to eq "ee_select_plan_during_oe"
    end
    it "should render mpi_indicator" do
      expect(@employee_notice.mpi_indicator).to eq "SHOP_D073"
    end
    it "should generate pdf" do
      @employee_notice.append_data
      @employee_notice.build
      @employee_notice.generate_pdf_notice
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end

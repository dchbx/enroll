require 'rails_helper'

RSpec.describe ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, benefit_group_assignment: benefit_group_assignment, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 2.month, plan: renewal_plan, aasm_state: 'coverage_termination_pending')}
  let(:renewal_plan) { FactoryGirl.create(:plan)}
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, :renewal_plan_id => renewal_plan.id)}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Employee must be notified when they successfully match to their employer',
                            :notice_template => 'notices/shop_employee_notices/employee_terminating_coverage_confirmation',
                            :notice_builder => 'ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation',
                            :event_name => 'notify_employee_confirming_coverage_termination',
                            :mpi_indicator => 'SHOP_D042',
                            :title => "Confirmation of Election To Terminate Coverage"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => { :hbx_enrollment_hbx_id => hbx_enrollment.hbx_id.to_s }
  }}

  let(:enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state:'coverage_termination_selected', coverage_kind: "dental")}

  describe "New" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employee_notice = ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employee_notice = ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation.new(census_employee, valid_params)
    end

    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq census_employee.employer_profile.staff_roles.first.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employee_notice = ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation.new(census_employee, valid_params)
      allow(enrollment).to receive(:aasm_state).and_return("coverage_termination_pending")
      allow(enrollment).to receive(:coverage_kind).and_return("dental")
      allow(census_employee).to receive(:published_benefit_group_assignment).and_return benefit_group_assignment
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return [enrollment]
    end

    it "should append data" do
      @employee_notice.append_data
      expect(@employee_notice.notice.enrollment.terminated_on).to eq hbx_enrollment.terminated_on
    end
  end
  
  describe "Rendering terminating_coverage_notice template and generate pdf" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employee_notice = ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation.new(census_employee, valid_params)
      allow(enrollment).to receive(:aasm_state).and_return("coverage_termination_pending")
      allow(enrollment).to receive(:coverage_kind).and_return("dental")
      allow(census_employee).to receive(:published_benefit_group_assignment).and_return benefit_group_assignment  
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return [enrollment]
    end

    it "should render terminating_coverage_notice" do
      expect(@employee_notice.template).to eq application_event.notice_template
    end

    it "should render terminating_coverage_notice" do
      expect(@employee_notice.mpi_indicator).to eq application_event.mpi_indicator
    end

    it "should render terminating_coverage_notice" do
      expect(@employee_notice.event_name).to eq application_event.event_name
    end

    it "should generate pdf" do
      @employee_notice.build
      @employee_notice.append_data
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end 

end

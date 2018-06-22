require 'rails_helper'

RSpec.describe ShopEmployerNotices::EmployeeTerminatingCoverage, :dbclean => :after_each do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id, coverage_terminated_on: TimeKeeper.date_of_record.end_of_month) }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, benefit_group_assignment: benefit_group_assignment, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 2.month, plan: renewal_plan, aasm_state: 'coverage_termination_pending', employee_role_id: employee_role.id, terminated_on: TimeKeeper.date_of_record.end_of_month)}
  let(:renewal_plan) { FactoryGirl.create(:plan)}
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, :renewal_plan_id => renewal_plan.id)}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Notice to employer when employee terminates coverage',
                            :notice_template => 'notices/shop_employer_notices/employee_terminating_coverage',
                            :notice_builder => 'ShopEmployerNotices::EmployeeTerminatingCoverage',
                            :event_name => 'notify_employer_when_employee_terminate_coverage',
                            :mpi_indicator => 'SHOP_D041',
                            :title => "Employee Terminating coverage"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => { :hbx_enrollment => hbx_enrollment.hbx_id.to_s}
  }}

  before do
    allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    @employer_notice = ShopEmployerNotices::EmployeeTerminatingCoverage.new(employer_profile, valid_params)
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::EmployeeTerminatingCoverage.new(employer_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployerNotices::EmployeeTerminatingCoverage.new(employer_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    it "should build notice with all necessory info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq employer_profile.staff_roles.first.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    it "should append data" do
      @employer_notice.append_data
      expect(@employer_notice.notice.enrollment.enrolled_count).to eq hbx_enrollment.humanized_dependent_summary.to_s
      expect(@employer_notice.notice.enrollment.employee_fullname).to eq hbx_enrollment.employee_role.person.full_name.titleize
      expect(@employer_notice.notice.enrollment.terminated_on).to eq hbx_enrollment.terminated_on
    end
  end

  describe "Rendering employee_terminating_coverage notice template and generate pdf" do
    it "should render employee_terminating_coverage notice" do
      expect(@employer_notice.template).to eq application_event.notice_template
    end

    it "should match mpi_indicator" do
      expect(@employer_notice.mpi_indicator).to eq application_event.mpi_indicator
    end

    it "should match event_name" do
      expect(@employer_notice.event_name).to eq application_event.event_name
    end
    it "should generate pdf" do
      @employer_notice.build
      @employer_notice.append_data
      @employer_notice.generate_pdf_notice
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end

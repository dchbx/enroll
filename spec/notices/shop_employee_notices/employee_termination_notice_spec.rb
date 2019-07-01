require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployeeNotices::EmployeeTerminationNotice, :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:person) {FactoryBot.create(:person, :with_family)}
  let(:family){ person.primary_family }
  let(:household){ family.active_household }
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, employee_role_id: employee_role.id, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package ) }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile) }
  let!(:sponsored_benefit) { initial_application.benefit_packages.first.sponsored_benefits.first }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                            household: household,
                                            family: family,
                                            hbx_enrollment_members: [hbx_enrollment_member],
                                            aasm_state: "coverage_terminated",
                                            coverage_kind: "health",
                                            external_enrollment: false,
                                            sponsored_benefit_id: sponsored_benefit.id,
                                            rating_area_id: rating_area.id )
  }

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
      expect(@employee_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  describe "append data" do
    before do
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return [hbx_enrollment]
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
      expect(@employee_notice.notice.census_employee.enrollments.first.plan.plan_name).to eq hbx_enrollment.plan.name
    end

    it "should return coverage kind" do
      expect(@employee_notice.notice.census_employee.enrollments.first.plan.coverage_kind).to eq hbx_enrollment.coverage_kind
    end

    it "should return enrolled count" do
      expect(@employee_notice.notice.census_employee.enrollments.first.enrolled_count).to eq hbx_enrollment.humanized_dependent_summary.to_s
    end

  end

  describe "render template and generate pdf" do
    before do
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return [hbx_enrollment]
      allow(census_employee).to receive(:coverage_terminated_on).and_return(TimeKeeper.date_of_record)
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

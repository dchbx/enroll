require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation, :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:person) {FactoryBot.create(:person, :with_family)}
  let(:family){ person.primary_family }
  let(:household){ family.active_household }
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, employee_role_id: employee_role.id, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: benefit_package ) }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile) }
  let!(:sponsored_benefit) { renewal_application.benefit_packages.first.sponsored_benefits.first }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                            household: household,
                                            family: family,
                                            hbx_enrollment_members: [hbx_enrollment_member],
                                            external_enrollment: false,
                                            sponsored_benefit_id: sponsored_benefit.id,
                                            rating_area_id: rating_area.id )
  }

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

  describe "New" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
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
      expect(@employee_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  describe "append data" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employee_notice = ShopEmployeeNotices::EmployeeTerminatingCoverageConfirmation.new(census_employee, valid_params)
      allow(hbx_enrollment).to receive(:aasm_state).and_return("coverage_termination_pending")
      allow(hbx_enrollment).to receive(:coverage_kind).and_return("health")
      allow(census_employee).to receive(:published_benefit_group_assignment).and_return benefit_group_assignment
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return [hbx_enrollment]
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
      allow(hbx_enrollment).to receive(:aasm_state).and_return("coverage_termination_pending")
      allow(hbx_enrollment).to receive(:coverage_kind).and_return("dental")
      allow(census_employee).to receive(:published_benefit_group_assignment).and_return benefit_group_assignment  
      allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return [hbx_enrollment]
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

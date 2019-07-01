require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal, :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:person) {FactoryBot.create(:person)}
  let(:family){ FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:household){ family.active_household }
  let!(:census_employee) { FactoryBot.create(:census_employee_with_active_and_renewal_assignment, employee_role_id: employee_role.id, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: benefit_package ) }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile) }
  let(:benefit_group_assignment) { census_employee.renewal_benefit_group_assignment }
  let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                            household: household,
                                            family: family,
                                            hbx_enrollment_members: [hbx_enrollment_member],
                                            coverage_kind: "health",
                                            external_enrollment: false,
                                            rating_area_id: rating_area.id )
  }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Renewal Open Enrollment available for Employee',
                            :notice_template => 'notices/shop_employee_notices/8b_renewal_open_enrollment_notice_for_employee',
                            :notice_builder => 'ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal',
                            :mpi_indicator => 'MPI_SHOP8B',
                            :event_name => 'employee_open_enrollment_no_auto_renewal',
                            :title => "Your Health Plan Open Enrollment Period has Begun"})
  }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal.new(census_employee, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal.new(census_employee, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal.new(census_employee, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal.new(census_employee, valid_parmas)
    end
    it "should build notice with all necessory info" do

      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  #ToDo Fix in DC new model after udpdating the notice builder
  xdescribe "append data" do
    before do
      @employee_notice = ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal.new(census_employee, valid_parmas)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
    end
    it "should append data" do
      hbx_enrollment.update_attributes(benefit_group_assignment_id: benefit_group_assignment.id)
      renewing_plan_year = employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING).first
      enrollment = census_employee.active_benefit_group_assignment.hbx_enrollments.first
      @employee_notice.append_data
      expect(@employee_notice.notice.plan_year.start_on).to eq renewing_plan_year.start_on
      expect(@employee_notice.notice.plan_year.open_enrollment_end_on).to eq renewing_plan_year.open_enrollment_end_on
      expect(@employee_notice.notice.plan.plan_name).to eq plan.name
    end
  end
end

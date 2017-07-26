require 'rails_helper'

RSpec.describe ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal do
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
  let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: renewal_benefit_group, census_employee: census_employee, aasm_state: "coverage_renewing") }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Renewal Open Enrollment available for Employee',
                            :notice_template => 'notices/shop_employee_notices/8a_renewal_open_enrollment_notice_for_employee',
                            :notice_builder => 'ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal',
                            :mpi_indicator => 'MPI_SHOP8A',
                            :event_name => 'employee_open_enrollment_auto_renewal',
                            :title => "Your Health Plan Open Enrollment Period has Begun"})
                          }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 2.month, plan: renewal_plan)}
  let(:renewal_plan) { FactoryGirl.create(:plan)}
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, :renewal_plan_id => renewal_plan.id)}

    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)
    end
    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    before do
      @employee_notice = ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal.new(census_employee, valid_parmas)
      benefit_group_assignment.plan_year.update_attribute(:aasm_state, "renewing_enrolled")
    end
    it "should append data" do
      hbx_enrollment.update_attributes(benefit_group_assignment_id: benefit_group_assignment.id)
      renewing_plan_year = employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING).first
      enrollment = census_employee.renewal_benefit_group_assignment.hbx_enrollments.first
      @employee_notice.append_data
      expect(@employee_notice.notice.plan_year.start_on).to eq renewing_plan_year.start_on
      expect(@employee_notice.notice.plan_year.open_enrollment_end_on).to eq renewing_plan_year.open_enrollment_end_on
      expect(@employee_notice.notice.plan.plan_name).to eq renewal_plan.name
      expect(@employee_notice.notice.enrollment.employee_cost).to eq enrollment.total_employee_cost.to_s
      expect(@employee_notice.notice.enrollment.enrollees).to eq enrollment.hbx_enrollment_members.map(&:person).map(&:full_name)
    end
  end

end
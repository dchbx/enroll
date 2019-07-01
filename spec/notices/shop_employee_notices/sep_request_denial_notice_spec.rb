require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployeeNotices::SepRequestDenialNotice, :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:hbx_profile)   { FactoryBot.create(:benefit_sponsors_organizations_hbx_profile, organization: abc_organization) }
  let(:renewal_bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, start_on: TimeKeeper.date_of_record.beginning_of_year, end_on: TimeKeeper.date_of_record.end_of_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.next_year.year,11,1), open_enrollment_end_on: Date.new((TimeKeeper.date_of_record+2.years).year,1,31)) }
  let(:bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, plan_year: TimeKeeper.date_of_record.beginning_of_year.next_year,  start_on: TimeKeeper.date_of_record.beginning_of_year.next_year, end_on: TimeKeeper.date_of_record.end_of_year.next_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.year,11,1), open_enrollment_end_on: Date.new(TimeKeeper.date_of_record.next_year.year,1,31)) }
  let(:person) {FactoryBot.create(:person)}
  let(:family){ FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:household){ family.active_household }
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, employee_role_id: employee_role.id, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: benefit_package ) }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile) }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
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
                            :name =>'Denial of SEP Requested by EE outside of allowable time frame',
                            :notice_template => 'notices/shop_employee_notices/sep_request_denial_notice',
                            :notice_builder => 'ShopEmployeeNotices::SepRequestDenialNotice',
                            :mpi_indicator => 'MPI_SHOP35',
                            :event_name => 'sep_request_denial_notice',
                            :title => "Special Enrollment Period Denial"})
                          }

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)
    end
    it "should build notice with all necessory info" do

      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  #ToDo Fix in DC new model after udpdating the notice builder
  xdescribe "append data" do
    let(:qle_on) {Date.new(TimeKeeper.date_of_record.year, 04, 14)}
    let(:end_on) {Date.new(TimeKeeper.date_of_record.year, 04, 18)}
    let(:special_enrollment_period) {[double("SpecialEnrollmentPeriod")]}
    let(:sep1) {family.special_enrollment_periods.new}
    let(:sep2) {family.special_enrollment_periods.new}
    let(:order) {[sep1,sep2]}

    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      allow(census_employee.employee_role.person.primary_family).to receive_message_chain("special_enrollment_periods.order_by").and_return(order)
      @employee_notice = ShopEmployeeNotices::SepRequestDenialNotice.new(census_employee, valid_params)
      sep1.qle_on = qle_on
      sep1.end_on = end_on
      sep1.title = "had a baby"
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive_message_chain(:benefit_sponsorship, :benefit_coverage_periods).and_return([bcp, renewal_bcp])
    end

    it "should append data" do
      sep = census_employee.employee_role.person.primary_family.special_enrollment_periods.order_by(:"created_at".desc)[0]
      
      @employee_notice.append_data
      expect(@employee_notice.notice.sep.qle_on).to eq qle_on
      expect(@employee_notice.notice.sep.end_on).to eq end_on
      expect(@employee_notice.notice.sep.title).to eq "had a baby"
      
      expect(@employee_notice.notice.plan_year.start_on).to eq plan_year.start_on+1.year

      expect(@employee_notice.notice.enrollment.ivl_open_enrollment_start_on).to eq bcp.open_enrollment_start_on
      expect(@employee_notice.notice.enrollment.ivl_open_enrollment_end_on).to eq bcp.open_enrollment_end_on
      expect(@employee_notice.notice.enrollment.effective_on).to eq bcp.start_on
      expect(@employee_notice.notice.enrollment.plan_year).to eq bcp.plan_year.year
    end
  end
end

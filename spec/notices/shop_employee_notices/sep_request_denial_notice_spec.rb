require 'rails_helper'

RSpec.describe ShopEmployeeNotices::SepRequestDenialNotice, :dbclean => :after_each do
  let(:hbx_profile) {double}
  let(:benefit_sponsorship) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, renewal_benefit_coverage_period: renewal_bcp, current_benefit_coverage_period: bcp) }
  let(:renewal_bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, start_on: TimeKeeper.date_of_record.beginning_of_year, end_on: TimeKeeper.date_of_record.end_of_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.next_year.year,11,1), open_enrollment_end_on: Date.new((TimeKeeper.date_of_record+2.years).year,1,31)) }
  let(:bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, plan_year: TimeKeeper.date_of_record.beginning_of_year.next_year,  start_on: TimeKeeper.date_of_record.beginning_of_year.next_year, end_on: TimeKeeper.date_of_record.end_of_year.next_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.year,11,1), open_enrollment_end_on: Date.new(TimeKeeper.date_of_record.next_year.year,1,31)) }
  let(:plan) { FactoryGirl.create(:plan) }
  let(:plan2) { FactoryGirl.create(:plan) }
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: TimeKeeper.date_of_record.beginning_of_year, :aasm_state => 'published' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, benefit_group_assignment: benefit_group_assignment, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month + 2.month, aasm_state: 'coverage_termination_pending')}
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let(:renewal_plan) { FactoryGirl.create(:plan)}
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, :renewal_plan_id => renewal_plan.id)}
  let(:qle) { FactoryGirl.create(:qualifying_life_event_kind)}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Denial of SEP Requested by EE outside of allowable time frame',
                            :notice_template => 'notices/shop_employee_notices/sep_request_denial_notice',
                            :notice_builder => 'ShopEmployeeNotices::SepRequestDenialNotice',
                            :mpi_indicator => 'SHOP_M033',
                            :event_name => 'sep_request_denial_notice',
                            :title => "Special Enrollment Period Denial"})
                          }

    let(:valid_params) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template,
        :options => {
          :qle_id => qle.id,
          :qle_reported_date => Date.new(TimeKeeper.date_of_record.year, 04, 14)
        }
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
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data notice template and genearte pdf" do
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
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive_message_chain(:benefit_sponsorship, :benefit_coverage_periods).and_return([bcp, renewal_bcp])
    end

    it "should append data" do
      sep = census_employee.employee_role.person.primary_family.special_enrollment_periods.order_by(:"created_at".desc)[0]
      @employee_notice.append_data
      expect(@employee_notice.notice.qle.qle_on).to eq qle_on
      expect(@employee_notice.notice.qle.title).to eq "Married"
      expect(@employee_notice.notice.plan_year.start_on).to eq plan_year.start_on
      expect(@employee_notice.notice.plan_year.renewing_start_on).to eq plan_year.start_on+1.year
      expect(@employee_notice.notice.plan_year.open_enrollment_end_on).to eq plan_year.open_enrollment_end_on
    end

    it "should render notice" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/sep_request_denial_notice"
    end
    it "should generate pdf" do



      @employee_notice.build
      @employee_notice.append_data
      file = @employee_notice.generate_pdf_notice
      
      expect(File.exist?(file.path)).to be true
    end    
  end  
end
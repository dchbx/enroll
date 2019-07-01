require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility, :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:hbx_profile)   { FactoryBot.create(:benefit_sponsors_organizations_hbx_profile, organization: abc_organization) }
  let(:renewal_bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, start_on: TimeKeeper.date_of_record.beginning_of_year, end_on: TimeKeeper.date_of_record.end_of_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.next_year.year,11,1), open_enrollment_end_on: Date.new((TimeKeeper.date_of_record+2.years).year,1,31)) }
  let(:bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, plan_year: TimeKeeper.date_of_record.beginning_of_year.next_year,  start_on: TimeKeeper.date_of_record.beginning_of_year.next_year, end_on: TimeKeeper.date_of_record.end_of_year.next_year, open_enrollment_start_on: Date.new(TimeKeeper.date_of_record.year,11,1), open_enrollment_end_on: Date.new(TimeKeeper.date_of_record.next_year.year,1,31)) }
  let(:person) {FactoryBot.create(:person)}
  let(:family){ FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:household){ family.active_household }
  let!(:census_employee) { FactoryBot.create(:census_employee, :with_active_assignment, employee_role_id: employee_role.id, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package ) }
  let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: abc_profile) }
  let(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, is_subscriber:true,  applicant_id: family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, :with_product, sponsored_benefit_package_id: benefit_group_assignment.benefit_group.id,
                                            household: household,
                                            hbx_enrollment_members: [hbx_enrollment_member],
                                            family: family,
                                            coverage_kind: "health",
                                            external_enrollment: false,
                                            rating_area_id: rating_area.id )
  } 
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Notification to employees regarding their Employer’s ineligibility.',
                            :notice_template => 'notices/shop_employee_notices/notification_to_employee_due_to_initial_employer_ineligibility',
                            :notice_builder => 'ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility',
                            :event_name => 'notify_employee_of_initial_employer_ineligibility',
                            :mpi_indicator => 'MPI_SHOP10047',
                            :title => "Termination of Employer’s Health Coverage Offered through DC Health Link"})
                          }

  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      @employee_notice = ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility.new(census_employee, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility.new(census_employee, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility.new(census_employee, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @employee_notice = ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility.new(census_employee, valid_parmas)
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
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive_message_chain(:benefit_sponsorship, :benefit_coverage_periods).and_return([bcp, renewal_bcp])
      @employee_notice = ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility.new(census_employee, valid_parmas)
    end
    it "should append data" do
      @employee_notice.append_data
      expect(@employee_notice.notice.plan_year.start_on).to eq plan_year.start_on
      expect(@employee_notice.notice.enrollment.ivl_open_enrollment_start_on).to eq bcp.open_enrollment_start_on
      expect(@employee_notice.notice.enrollment.ivl_open_enrollment_end_on).to eq bcp.open_enrollment_end_on
    end
  end

end

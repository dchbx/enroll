require 'rails_helper'

RSpec.describe ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop, :dbclean => :after_each do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment,household: family.active_household, plan_id: plan.id, benefit_group_id: benefit_group.id, employee_role_id: employee_role.id)}
  let(:person) { FactoryGirl.create(:person)}
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:employer_profile_id) { employer_profile.id }
  let(:employee_role) {FactoryGirl.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let(:organization) {FactoryGirl.create(:organization, legal_name: "Delta Dental")}
  let(:carrier_profile) {FactoryGirl.create(:carrier_profile, organization: organization)}
  let(:plan) {FactoryGirl.create(:plan, :with_dental_coverage, carrier_profile: carrier_profile, market: "shop")}
  let(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile)}
  let(:benefit_group)     { FactoryGirl.create(:benefit_group, plan_year: plan_year)}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Renewal EEs Dental Carriers are Exiting SHOP market notice',
                            :notice_template => 'notices/shop_employee_notices/notify_renewal_employees_dental_carriers_exiting_shop',
                            :notice_builder => 'ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop',
                            :event_name => 'notify_renewal_employees_dental_carriers_exiting_shop',
                            :mpi_indicator => 'SHOP_D092',
                            :title => "Dental Carrier Exit from DC Health Link’s Small Business Marketplace"})
                          }

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => {
        :hbx_enrollment => hbx_enrollment.hbx_id.to_s
      }
  }}

  before do
    @employee_notice = ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop.new(census_employee, valid_params)
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::NotifyRenewalEmployeesDentalCarriersExitingShop.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do 
      @employee_notice.build
    end

    it "should build notice with primary full name" do
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
    end
    
    it "should build notice with organization name" do
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do
    before do
      @employee_notice.append_data
    end

    it "should append plan name" do
      expect(@employee_notice.notice.plan.plan_name).to eq plan.name
    end

    it "should append plan year start_on date" do
      expect(@employee_notice.notice.plan.coverage_start_on).to eq hbx_enrollment.benefit_group.plan_year.start_on
    end

    it "should append plan year end_on date" do
      expect(@employee_notice.notice.plan.coverage_end_on).to eq hbx_enrollment.benefit_group.plan_year.end_on
    end

    it "should append carrier name" do
      expect(@employee_notice.notice.plan.plan_carrier).to eq plan.carrier_profile.organization.legal_name
    end
  end

  describe "should render template" do
    it "render notify_renewal_employees_dental_carriers_exiting_shop" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/notify_renewal_employees_dental_carriers_exiting_shop"
    end
  end

  describe "for generating pdf" do
    it "should generate pdf" do
      @employee_notice.build
      @employee_notice.append_data
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end

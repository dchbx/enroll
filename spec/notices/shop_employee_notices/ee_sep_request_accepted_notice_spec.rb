require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployeeNotices::EeSepRequestAcceptedNotice, dbclean: :after_each do
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
                                            family: family,
                                            household: household,
                                            hbx_enrollment_members: [hbx_enrollment_member],
                                            coverage_kind: "health",
                                            external_enrollment: false,
                                            sponsored_benefit_id: sponsored_benefit.id,
                                            rating_area_id: rating_area.id )
  }

  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'EE SEP Requested Accepted',
                            :notice_template => 'notices/shop_employee_notices/ee_sep_request_accepted_notice',
                            :notice_builder => 'ShopEmployeeNotices::EeSepRequestAcceptedNotice',
                            :event_name => 'ee_sep_request_accepted_notice',
                            :mpi_indicator => 'MPI_SHOP36',
                            :title => "Special Enrollment Period Approval"})
                          }
  let(:qle_on) {Date.new(TimeKeeper.date_of_record.year, 04, 14)}
  let(:end_on) {qle_on+30.days}
  let(:title) { "had a baby"}

  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :options => {:qle_on => qle_on.to_s, :end_on => end_on.to_s, :title => title},
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employee_notice = ShopEmployeeNotices::EeSepRequestAcceptedNotice.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::EeSepRequestAcceptedNotice.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::EeSepRequestAcceptedNotice.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employee_notice = ShopEmployeeNotices::EeSepRequestAcceptedNotice.new(census_employee, valid_params)
    end

    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq census_employee.employer_profile.staff_roles.first.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  describe "append data" do
    let(:special_enrollment_period) {[double("SpecialEnrollmentPeriod")]}
    let(:sep1) {family.special_enrollment_periods.new}
    let(:sep2) {family.special_enrollment_periods.new}
    let(:order) {[sep1,sep2]}

    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      allow(census_employee.employee_role.person.primary_family).to receive_message_chain("special_enrollment_periods.order_by").and_return(order)
      @employee_notice = ShopEmployeeNotices::EeSepRequestAcceptedNotice.new(census_employee, valid_params)
      sep1.qle_on = qle_on
      sep1.end_on = end_on
      sep1.title = title
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      @employee_notice.append_data
      @employee_notice.build
      @employee_notice.generate_pdf_notice
    end

    it "should append data" do
      sep = census_employee.employee_role.person.primary_family.special_enrollment_periods.order_by(:"created_at".desc)[0]
      @employee_notice.append_data
      expect(@employee_notice.notice.sep.qle_on).to eq qle_on
      expect(@employee_notice.notice.sep.end_on).to eq end_on
      expect(@employee_notice.notice.sep.title).to eq title
    end

    it "should render ee_sep_request_accepted_notice" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/ee_sep_request_accepted_notice"
    end

    it "should generate pdf" do
      @employee_notice.build
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end

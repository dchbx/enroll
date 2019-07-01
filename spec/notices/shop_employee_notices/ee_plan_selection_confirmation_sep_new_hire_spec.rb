require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployeeNotices::EePlanConfirmationSepNewHire, dbclean: :after_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup renewal application"

  let(:person) {FactoryBot.create(:person)}
  let(:family){ FactoryBot.create(:family, :with_primary_family_member) }
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
                                            coverage_kind: "health",
                                            external_enrollment: false,
                                            sponsored_benefit_id: sponsored_benefit.id,
                                            rating_area_id: rating_area.id )
  }

  let(:application_event) { double("ApplicationEventKind", {
    :name => 'Notification to employees regarding plan purchase during Open Enrollment or an SEP',
    :notice_template => 'notices/shop_employee_notices/ee_plan_selection_confirmation_sep_new_hire',
    :notice_builder => 'ShopEmployeeNotices::EePlanConfirmationSepNewHire',
    :event_name => 'ee_plan_selection_confirmation_sep_new_hire',
    :mpi_indicator => 'MPI_SHOPDAE074',
    :title => "Employee Plan Selection Confirmation"})
  }

  let(:valid_params) { {
    :subject => application_event.title,
    :mpi_indicator => application_event.mpi_indicator,
    :event_name => application_event.event_name,
    :template => application_event.notice_template,
    :options => { :hbx_enrollment => hbx_enrollment.hbx_id.to_s }
  }}
  let(:rate_schedule_date) {TimeKeeper.date_of_record}
  let(:cost_calculator) { HbxEnrollmentSponsoredCostCalculator.new(hbx_enrollment) }

  describe "New" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params)
    end
    context "valid params" do
      it "should initialze" do
        expect { ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params) }.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator, :subject, :template].each do |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect { ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params) }.to raise_error(RuntimeError, "Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params)
    end

    it "should build notice with all necessory info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq census_employee.employer_profile.staff_roles.first.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  describe "append data" do
    let(:member_enrollment) {BenefitSponsors::Enrollments::MemberEnrollment.new(member_id:hbx_enrollment_member.id, product_price:BigDecimal(100),sponsor_contribution:BigDecimal(100))}
    let(:group_enrollment) {BenefitSponsors::Enrollments::GroupEnrollment.new(product: hbx_enrollment.product, member_enrollments:[member_enrollment], rate_schedule_date: rate_schedule_date)}
    let(:decorated_hbx_enrollment) {double( member_enrollments:[member_enrollment], product_cost_total: 0.0 ,sponsor_contribution_total: 0.0)}
    let(:member_group) { BenefitSponsors::Members::MemberGroup.new( group_enrollment: group_enrollment )}

    before do
      hbx_enrollment.sponsored_benefit_id = hbx_enrollment.sponsored_benefit_package.sponsored_benefits.first.id
      hbx_enrollment.save!
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
      allow(sponsored_benefit).to receive(:rate_schedule_date).and_return(rate_schedule_date)
      allow(HbxEnrollmentSponsoredCostCalculator).to receive(:new).with(hbx_enrollment).and_return(cost_calculator)
      allow(cost_calculator).to receive(:groups_for_products).with([hbx_enrollment.product]).and_return([member_group])
      @employer_notice = ShopEmployeeNotices::EePlanConfirmationSepNewHire.new(census_employee, valid_params)
      @employer_notice.deliver
    end

    it "should append data" do
      expect(@employer_notice.notice.enrollment.effective_on.to_s).to eq(hbx_enrollment.effective_on.to_s)
      # expect(@employer_notice.notice.enrollment.plan.plan_name).to eq(hbx_enrollment.product.name)
      expect(@employer_notice.notice.enrollment.employee_cost).to eq("0.0")
      expect(@employer_notice.notice.enrollment.employer_contribution).to eq("0.0")
    end

    it "should render ee_plan_selection_notice" do
      expect(@employer_notice.template).to eq "notices/shop_employee_notices/ee_plan_selection_confirmation_sep_new_hire"
    end

    it "should generate pdf" do
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end

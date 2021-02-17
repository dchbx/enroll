# frozen_string_literal: true

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe Operations::Shop::DependentAgeOff, type: :model, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  include_context "setup employees with benefits"
  let!(:person)          { FactoryBot.create(:person, :with_consumer_role) }
  let!(:family)          { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:hbx_enrollment)  { FactoryBot.create(:hbx_enrollment, :individual_unassisted, household: family.active_household, family: family) }

  let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
  let(:effective_on) { current_effective_date }
  let(:hired_on) { TimeKeeper.date_of_record - 3.months }
  let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member_and_dependent)}
  let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
  let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

  let(:aasm_state) { :active }
  let(:census_employee) do
    create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship,
                                                      employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package,
                                                      hired_on: hired_on, created_at: hired_on, updated_at: hired_on)
  end
  let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
  let(:enrollment_kind) { "open_enrollment" }
  let(:special_enrollment_period_id) { nil }
  let!(:family_member1) {shop_family.family_members.first}
  let!(:family_member2) {shop_family.family_members.second}
  let!(:family_member3) {shop_family.family_members.last}
  let!(:shop_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      household: shop_family.latest_household,
                      coverage_kind: "health",
                      family: shop_family,
                      effective_on: effective_on,
                      enrollment_kind: enrollment_kind,
                      kind: "employer_sponsored",
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: employee_role.id,
                      product: sponsored_benefit.reference_product,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end
  let!(:enr_mem1) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member1.id, is_subscriber: family_member1.is_primary_applicant, hbx_enrollment: shop_enrollment) }
  let!(:enr_mem2) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member2.id, is_subscriber: family_member2.is_primary_applicant, hbx_enrollment: shop_enrollment) }
  let!(:enr_mem3) { FactoryBot.create(:hbx_enrollment_member, applicant_id: family_member3.id, is_subscriber: family_member3.is_primary_applicant, hbx_enrollment: shop_enrollment) }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end


  describe "Automation period check" do
    if ::EnrollRegistry[:aca_shop_dependent_age_off].settings(:period).item == :annual
      context 'Annual' do
        it 'Should fail when configured annually' do
          result = subject.call(new_date: Date.new(2020,7,1))
          expect(result.failure).to eq("Cannot process the request, because shop dependent age off is not set for end of every month")
        end
      end
    end


    if ::EnrollRegistry[:aca_shop_dependent_age_off].settings(:period).item == :monthly
      context 'Monthly' do
        it 'Should fail when configured annually' do
          result = subject.call(new_date: Date.new(2020,7,1))
          expect(result.success).to eq("Successfully dropped dependents for SHOP market")
        end
      end
    end
  end

  # rubocop:disable Style/IdenticalConditionalBranches
  context 'valid date' do
    it 'Should process the request when configured annually' do
      result = subject.call(new_date: TimeKeeper.date_of_record.beginning_of_year)
      expect(result.success).to eq('Successfully dropped dependents for SHOP market')
    end
  end
  # rubocop:enable Style/IdenticalConditionalBranches

  context 'initialize logger' do
    it "Should initialize logger" do
      result = subject.initialize_logger("shop")
      expect(result.success.class).to eq(Logger)
    end
  end

  context 'pick shop enrollments and process termination' do
    before do
      census_employee.update_attributes(employee_role_id: employee_role.id)
      shop_enrollment.reload
      census_employee.reload
    end

    it 'Should pick shop enrollments and process for age off for 2 dependents.' do
      expect(shop_family.active_household.hbx_enrollments.count).to eq(1)
      expect(shop_enrollment.hbx_enrollment_members.count).to eq(3)
      result = subject.call(new_date: TimeKeeper.date_of_record.beginning_of_year)
      expect(result.success).to eq("Successfully dropped dependents for SHOP market")
      shop_family.reload
      expect(shop_family.active_household.hbx_enrollments.count).to eq(2)
      expect(shop_family.active_household.hbx_enrollments.to_a.first.aasm_state).to eq("coverage_canceled")
      expect(shop_family.active_household.hbx_enrollments.to_a.last.hbx_enrollment_members.count).to eq(1)
      expect(shop_family.active_household.hbx_enrollments.last.aasm_state).to eq("coverage_enrolled")
      expect(shop_family.active_household.hbx_enrollments.last.workflow_state_transitions.any?{|w| w.from_state == "coverage_reinstated"}).to eq false
    end
  end

  context 'pick shop enrollments and process' do
    before do
      census_employee.update_attributes(employee_role_id: employee_role.id)
      shop_enrollment.reload
      census_employee.reload
      family_member3.person.update_attributes(dob: (TimeKeeper.date_of_record - 1.year))
    end

    it 'Should pick shop enrollments and process for age off for 1 dependent.' do
      expect(shop_family.active_household.hbx_enrollments.count).to eq(1)
      expect(shop_enrollment.hbx_enrollment_members.count).to eq(3)
      result = subject.call(new_date: TimeKeeper.date_of_record.beginning_of_year)
      expect(result.success).to eq("Successfully dropped dependents for SHOP market")
      shop_family.reload
      expect(shop_family.active_household.hbx_enrollments.count).to eq(2)
      expect(shop_family.active_household.hbx_enrollments.to_a.first.aasm_state).to eq("coverage_canceled")
      expect(shop_family.active_household.hbx_enrollments.to_a.last.hbx_enrollment_members.count).to eq(2)
    end
  end
end

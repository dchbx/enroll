require 'rails_helper'

RSpec.describe Factories::PlanYearRenewalFactory, type: :model, dbclean: :after_each do

  let(:calender_year) { TimeKeeper.date_of_record.year }
  let(:date_of_record_to_use) { Date.new(calender_year, 2, 1)}

  let(:organization) {
    org = FactoryGirl.create :organization, legal_name: "Corp 1"
    employer_profile = FactoryGirl.create :employer_profile, organization: org
    active_plan_year = FactoryGirl.create :plan_year, employer_profile: employer_profile, aasm_state: :active, :start_on => Date.new(calender_year - 1, 5, 1), :end_on => Date.new(calender_year, 4, 30),
    :open_enrollment_start_on => Date.new(calender_year - 1, 4, 1), :open_enrollment_end_on => Date.new(calender_year - 1, 4, 10), fte_count: 5
    benefit_group = FactoryGirl.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
    owner = FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
    2.times{|i| FactoryGirl.create :census_employee, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years + i.days }

    employer_profile.census_employees.each do |ce|
      ce.add_benefit_group_assignment benefit_group, benefit_group.start_on
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      ce.update_attributes({employee_role: employee_role})
      family = Family.find_or_build_from_employee_role(employee_role)

      enrollment = HbxEnrollment.create_from(
        employee_role: employee_role,
        coverage_household: family.households.first.coverage_households.first,
        benefit_group_assignment: ce.active_benefit_group_assignment,
        benefit_group: benefit_group,
        )
      enrollment.update_attributes(:aasm_state => 'coverage_selected')
    end

    org
  }

  let(:renewal_plan) { FactoryGirl.create(:plan, :with_premium_tables) }


  context '.renew' do

    before do
      TimeKeeper.set_date_of_record_unprotected!(date_of_record_to_use)
    end

    after :all do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    it 'should renew the employer profile' do
      employer_profile = organization.employer_profile
      active_plan_year = employer_profile.active_plan_year
      renewing_plan_year = employer_profile.plan_years.renewing.first
      expect(renewing_plan_year.present?).to be_falsey
      active_plan_year.benefit_groups.first.reference_plan.update_attributes({:renewal_plan_id => renewal_plan._id })

      plan_year_renewal_factory = Factories::PlanYearRenewalFactory.new
      plan_year_renewal_factory.employer_profile = organization.employer_profile
      plan_year_renewal_factory.is_congress = false
      plan_year_renewal_factory.renew

      renewing_plan_year = employer_profile.plan_years.renewing.first
      expect(renewing_plan_year.present?).to be_truthy
      expect(renewing_plan_year.aasm_state).to eq 'renewing_draft'

      renewing_plan_year_start = active_plan_year.start_on + 1.year
      expect(renewing_plan_year.start_on).to eq renewing_plan_year_start
      expect(renewing_plan_year.open_enrollment_start_on).to eq (renewing_plan_year_start - 2.months)
      expect(renewing_plan_year.open_enrollment_end_on).to eq (renewing_plan_year_start - 1.month + (Settings.aca.shop_market.renewal_application.monthly_open_enrollment_end_on - 1).days)

      employer_profile.census_employees.each do |ce|
        expect(ce.renewal_benefit_group_assignment.present?).to be_truthy
      end
    end
  end
end

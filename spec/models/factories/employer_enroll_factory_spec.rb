require 'rails_helper'

RSpec.describe Factories::EmployerEnrollFactory, type: :model, dbclean: :after_each do

  let(:calendar_year) { TimeKeeper.date_of_record.year }
  let(:date_of_record_to_use) { Date.new(calendar_year, 5, 1) }

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  context 'New Employer' do
    let(:organization) {
      org = FactoryBot.create :organization, legal_name: "Corp 1"
      employer_profile = FactoryBot.create :employer_profile, organization: org
      plan_year = FactoryBot.create :plan_year, employer_profile: employer_profile, aasm_state: :enrolled, :start_on => Date.new(calendar_year, 5, 1), :end_on => Date.new(calendar_year+1, 4, 30),
      :open_enrollment_start_on => Date.new(calendar_year, 4, 1), :open_enrollment_end_on => Date.new(calendar_year, 4, 10), fte_count: 5
      benefit_group = FactoryBot.create :benefit_group, :with_valid_dental, plan_year: plan_year
      owner = FactoryBot.create :census_employee, :old_case, :owner, employer_profile: employer_profile
      2.times{|i| FactoryBot.create :census_employee, :old_case, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years + i.days }
      employer_profile.census_employees.each do |ce|
        person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
        ce.update_attributes({employee_role: employee_role})
        family = Family.find_or_build_from_employee_role(employee_role)

        create(
          :hbx_enrollment,
          family: family,
          household: family.active_household,
          coverage_kind: "health",
          effective_on: benefit_group.start_on,
          enrollment_kind: 'open_enrollment',
          kind: 'employer_sponsored',
          benefit_group_id: benefit_group.id,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
          aasm_state: (ce.is_business_owner? ? 'shopping' : 'coverage_selected')
        )
      end

      org
    }

    context 'with valid published plan year' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(date_of_record_to_use)
      end

      it 'should begin the plan year' do
        employer_profile = organization.employer_profile
        employer_enroll_factory = Factories::EmployerEnrollFactory.new
        employer_enroll_factory.date = date_of_record_to_use
        employer_enroll_factory.employer_profile = employer_profile
        employer_enroll_factory.begin

        expect(employer_profile.plan_years.first.aasm_state).to eq 'active'
        employer_profile.census_employees.each do |ce|
          if ce.is_business_owner?
            expect(ce.active_benefit_group_assignment.aasm_state).to eq 'initialized'
          else
            expect(ce.active_benefit_group_assignment.aasm_state).to eq 'coverage_selected'
          end
        end
        expect(employer_profile.aasm_state).to eq 'enrolled'
      end
    end

    context 'without a valid published plan year' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(date_of_record_to_use)
      end

      it 'should not begin the plan year' do
        employer_profile = organization.employer_profile
        employer_profile.plan_years.first.update_attributes({:aasm_state => 'draft'})
        employer_enroll_factory = Factories::EmployerEnrollFactory.new
        employer_enroll_factory.date = date_of_record_to_use
        employer_enroll_factory.employer_profile = employer_profile
        employer_enroll_factory.begin

        expect(employer_profile.plan_years.first.aasm_state).to eq 'draft'
        employer_profile.census_employees.each do |ce|
          expect(ce.active_benefit_group_assignment.aasm_state).to eq 'initialized'
        end
        expect(employer_profile.aasm_state).to eq 'applicant'
      end
    end
  end

  context "Renewing employer" do
    let(:organization) {
      org = FactoryBot.create :organization, legal_name: "Corp 1"
      employer_profile = FactoryBot.create :employer_profile, organization: org
      active_plan_year = FactoryBot.create :plan_year, employer_profile: employer_profile, aasm_state: :active, :start_on => Date.new(calendar_year - 1, 5, 1), :end_on => Date.new(calendar_year, 4, 30),
      :open_enrollment_start_on => Date.new(calendar_year - 1, 4, 1), :open_enrollment_end_on => Date.new(calendar_year - 1, 4, 10), fte_count: 5
      renewing_plan_year = FactoryBot.create :plan_year, employer_profile: employer_profile, aasm_state: :renewing_enrolled, :start_on => Date.new(calendar_year, 5, 1), :end_on => Date.new(calendar_year+1, 4, 30),
      :open_enrollment_start_on => Date.new(calendar_year, 4, 1), :open_enrollment_end_on => Date.new(calendar_year, 4, 10), fte_count: 5
      benefit_group = FactoryBot.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
      renewing_benefit_group = FactoryBot.create :benefit_group, :with_valid_dental, plan_year: renewing_plan_year
      owner = FactoryBot.create :census_employee, :old_case, :owner, employer_profile: employer_profile
      2.times{|i| FactoryBot.create :census_employee, :old_case, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years + i.days }
      employer_profile.census_employees.each do |ce|
        person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
        employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
        ce.update_attributes({employee_role: employee_role})
        family = Family.find_or_build_from_employee_role(employee_role)

        enrollment = create(
          :hbx_enrollment,
          family: family,
          household: family.active_household,
          coverage_kind: "health",
          effective_on: benefit_group.start_on,
          enrollment_kind: 'open_enrollment',
          kind: 'employer_sponsored',
          benefit_group_id: benefit_group.id,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
          aasm_state: 'coverage_selected'
        )
        ce.active_benefit_group_assignment.update_attributes(aasm_state: 'coverage_selected', hbx_enrollment_id: enrollment.id)


        enrollment = create(
          :hbx_enrollment,
          family: family,
          household: family.active_household,
          coverage_kind: "health",
          effective_on: renewing_benefit_group.start_on,
          enrollment_kind: 'open_enrollment',
          kind: 'employer_sponsored',
          benefit_group_id: renewing_benefit_group.id,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: ce.renewal_benefit_group_assignment.id,
          aasm_state: 'auto_renewing'
        )

        ce.renewal_benefit_group_assignment.update_attributes(aasm_state: 'auto_renewing', hbx_enrollment_id: enrollment.id)
      end

      org
    }

    context 'Renewing Employer with renewing published plan year' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(date_of_record_to_use)
      end

      it 'should begin renewing plan year' do
        employer_profile = organization.employer_profile
        active_plan_year = employer_profile.plan_years.detect{|py| !(py.start_on..py.end_on).cover?(date_of_record_to_use) }
        employer_profile.census_employees.each do |ce|
          expect(ce.active_benefit_group_assignment.benefit_group).to eq active_plan_year.benefit_groups.first
        end

        employer_enroll_factory = Factories::EmployerEnrollFactory.new
        employer_enroll_factory.date = date_of_record_to_use
        employer_enroll_factory.employer_profile = employer_profile
        employer_enroll_factory.begin

        renewing_plan_year = employer_profile.plan_years.detect{|py| (py.start_on..py.end_on).cover?(date_of_record_to_use) }
        expect(renewing_plan_year.aasm_state).to eq 'active'

        employer_profile.census_employees.each do |ce|
          expect(ce.active_benefit_group_assignment.benefit_group).to eq renewing_plan_year.benefit_groups.first
          expect(ce.active_benefit_group_assignment.aasm_state).to eq 'auto_renewing'
        end
        expect(employer_profile.aasm_state).to eq 'enrolled'
      end
    end

    context 'Renewing Employer without valid renewing published plan year' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(date_of_record_to_use)
      end

      it 'should not begin renewing plan year' do
        employer_profile = organization.employer_profile
        renewing_plan_year = employer_profile.plan_years.detect{|py| (py.start_on..py.end_on).cover?(date_of_record_to_use) }
        renewing_plan_year.update_attributes({:aasm_state => 'renewing_draft'})

        active_plan_year = employer_profile.plan_years.detect{|py| !(py.start_on..py.end_on).cover?(date_of_record_to_use) }
        employer_profile.census_employees.each do |ce|
          expect(ce.active_benefit_group_assignment.benefit_group).to eq active_plan_year.benefit_groups.first
        end

        employer_enroll_factory = Factories::EmployerEnrollFactory.new
        employer_enroll_factory.date = date_of_record_to_use
        employer_enroll_factory.employer_profile = employer_profile
        employer_enroll_factory.begin

        renewing_plan_year = employer_profile.plan_years.detect{|py| (py.start_on..py.end_on).cover?(date_of_record_to_use) }
        expect(renewing_plan_year.aasm_state).to eq 'renewing_draft'

        employer_profile.census_employees.each do |ce|
          expect(ce.active_benefit_group_assignment.benefit_group).not_to eq renewing_plan_year.benefit_groups.first
          expect(ce.active_benefit_group_assignment.aasm_state).to eq 'coverage_selected'
        end
        expect(employer_profile.aasm_state).to eq 'applicant'
      end
    end
  end

  context '.end' do
    context 'When employer active plan year ended' do

      let(:organization) {
        org = FactoryBot.create :organization, legal_name: "Corp 1"
        employer_profile = FactoryBot.create :employer_profile, organization: org
        active_plan_year = FactoryBot.create :plan_year, employer_profile: employer_profile, aasm_state: :active, :start_on => Date.new(calendar_year - 1, 5, 1), :end_on => Date.new(calendar_year, 4, 30),
        :open_enrollment_start_on => Date.new(calendar_year - 1, 4, 1), :open_enrollment_end_on => Date.new(calendar_year - 1, 4, 10), fte_count: 5
        renewing_plan_year = FactoryBot.create :plan_year, employer_profile: employer_profile, aasm_state: :renewing_enrolled, :start_on => Date.new(calendar_year, 5, 1), :end_on => Date.new(calendar_year+1, 4, 30),
        :open_enrollment_start_on => Date.new(calendar_year, 4, 1), :open_enrollment_end_on => Date.new(calendar_year, 4, 10), fte_count: 5
        benefit_group = FactoryBot.create :benefit_group, :with_valid_dental, plan_year: active_plan_year
        renewing_benefit_group = FactoryBot.create :benefit_group, :with_valid_dental, plan_year: renewing_plan_year
        owner = FactoryBot.create :census_employee, :old_case, :owner, employer_profile: employer_profile
        2.times{|i| FactoryBot.create :census_employee, :old_case, employer_profile: employer_profile, dob: TimeKeeper.date_of_record - 30.years + i.days }
        employer_profile.census_employees.each do |ce|
          person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
          employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
          ce.update_attributes({:employee_role =>  employee_role })
          family = Family.find_or_build_from_employee_role(employee_role)
          
          enrollment = create(
            :hbx_enrollment,
            family: family,
            household: family.active_household,
            coverage_kind: "health",
            effective_on: benefit_group.start_on,
            enrollment_kind: 'open_enrollment',
            kind: 'employer_sponsored',
            benefit_group_id: benefit_group.id,
            employee_role_id: employee_role.id,
            benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
            aasm_state: 'coverage_selected'
            )
          ce.active_benefit_group_assignment.update_attributes(aasm_state: 'coverage_selected', hbx_enrollment_id: enrollment.id)

          create(
            :hbx_enrollment,
            family: family,
            household: family.active_household,
            coverage_kind: "health",
            effective_on: renewing_benefit_group.start_on,
            enrollment_kind: 'open_enrollment',
            kind: 'employer_sponsored',
            benefit_group_id: renewing_benefit_group.id,
            employee_role_id: employee_role.id,
            benefit_group_assignment_id: ce.renewal_benefit_group_assignment.id,
            aasm_state: 'auto_renewing'
            )
        end

        org
      }

      before do
        TimeKeeper.set_date_of_record_unprotected!(date_of_record_to_use)
      end

      it 'should expire plan year with previous year enrollments' do
        employer_profile = organization.employer_profile
        active_plan_year = employer_profile.plan_years.detect{|py| !(py.start_on..py.end_on).cover?(date_of_record_to_use) }
        expiring_enrollments = HbxEnrollment.find_by_benefit_groups(active_plan_year.benefit_groups)

        expect(active_plan_year.aasm_state).to eq 'active'

        employer_enroll_factory = Factories::EmployerEnrollFactory.new
        employer_enroll_factory.date = date_of_record_to_use
        employer_enroll_factory.employer_profile = employer_profile
        employer_enroll_factory.end

        expect(active_plan_year.aasm_state).to eq 'expired'

        employer_profile.census_employees.each do |ce|
          expect(ce.active_benefit_group_assignment).to be_nil
          expired_assignment = ce.benefit_group_assignments.detect{|bg_assignment| bg_assignment.benefit_group == active_plan_year.benefit_groups.first }
          expect(expired_assignment.aasm_state).to eq 'coverage_expired'
        end

        expect(expiring_enrollments.size).to eq 3
        expiring_enrollments.each do |enrollment|
          enrollment.reload
          expect(enrollment.aasm_state).to eq 'coverage_expired'
        end
      end
    end
  end
end

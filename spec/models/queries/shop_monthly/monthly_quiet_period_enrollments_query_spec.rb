require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe "a monthly inital employer quiet period enrollments query" do

  describe "given an employer who has completed their first open enrollment" do
    describe "with employees who have made the following plan selections:
       - employee A has purchased:
         - One health enrollment during OE (Enrollment 1)
       - employee B has purchased:
         - One health enrollment during Quiet Period(Enrollment 2)
         - One health waiver during Quiet Period(Enrollment 3)
       - employee C has purchased:
         - One health enrollment during Quiet Period(Enrollment 4)
         - One dental enrollment during Quiet Period(Enrollment 5)
         - Then another health enrollment outside Quiet Period(Enrollment 6)
       - employee D has purchased:
         - One health enrollment early hours of 29th UTC time(Enrollment 7)
       - employee E has purchased:
         - One health enrollment during OE(Enrollment 8)
         - One health enrollment during Quiet Period(Enrollment 9)
         - Another health enrollment during Quiet Period(Enrollment 10)

         - One new hire health enrollment during OE (Enrollment 11) with effective GREATER than plan year start date
         - One new hire health enrollment during Quiet Period (Enrollment 12) with effective GREATER than plan year start date
         - One new hire dental enrollment during OE (Enrollment 13) with effective GREATER than plan year start date
         - One new hire dental enrollment during Quiet Period (Enrollment 14) with effective GREATER than plan year start date

         - One new hire health enrollment during OE (Enrollment 15) with effective as start date of the plan year

         - One health enrollment during Quiet Period(Enrollment 16) with renewal benefit application

    ", dbclean: :after_each do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"
      include_context "setup employees"

      let(:product_kinds)  { [:health, :dental] }
      let(:dental_sponsored_benefit) { true }

      let(:current_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
      let(:effective_on) { current_effective_date }
      let(:aasm_state) { :active }

      let(:initial_employer) {
        abc_profile
      }

      let(:plan_year) {
        initial_application
      }

      let(:quiet_period_end_on) {
        Settings.aca.shop_market.initial_application.quiet_period.mday
      }

      let(:quiet_period_end_date) {
        plan_year.start_on + (Settings.aca.shop_market.initial_application.quiet_period.month_offset).months + (Settings.aca.shop_market.initial_application.quiet_period.mday-1).days
      }

      let(:initial_employees) {
        # FactoryBot.create_list(:census_employee_with_active_assignment, 5, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: initial_employer,
        #   benefit_group: plan_year.benefit_groups.first)
        census_employees
      }

      let(:employee_A) {
        ce = initial_employees[0]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_1) {
        create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: plan_year.open_enrollment_end_on - 10.day)
      }

      let(:employee_B) {
        ce = initial_employees[1]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_2) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: quiet_period_end_date.prev_day)
      }

      let!(:enrollment_3) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: quiet_period_end_date.prev_day, status: 'inactive', parent: enrollment_2)
      }

      let(:employee_C) {
        ce = initial_employees[2]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_4) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.prev_day)
      }

      let!(:enrollment_5) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.prev_day, coverage_kind: 'dental')
      }

      let!(:enrollment_6) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date + 2.days)
      }

      let(:employee_D) {
        ce = initial_employees[3]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_7) {
        create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.active_benefit_group_assignment, employee_role: employee_D, submitted_at: quiet_period_end_date.end_of_day - 1.hour)
      }

      let(:employee_E) {
        ce = initial_employees[4]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_8) {
        create_enrollment(family: employee_E.person.primary_family, benefit_group_assignment: employee_E.census_employee.active_benefit_group_assignment, employee_role: employee_E, submitted_at: plan_year.open_enrollment_end_on - 10.day)
      }

      let!(:enrollment_9) {
        create_enrollment(family: employee_E.person.primary_family, benefit_group_assignment: employee_E.census_employee.active_benefit_group_assignment, employee_role: employee_E, submitted_at: quiet_period_end_date - 2.days, enrollment_kind: 'special_enrollment', parent: enrollment_8)
      }

      let!(:enrollment_10) {
        create_enrollment(family: employee_E.person.primary_family, benefit_group_assignment: employee_E.census_employee.active_benefit_group_assignment, employee_role: employee_E, submitted_at: quiet_period_end_date.prev_day, enrollment_kind: 'special_enrollment', parent: enrollment_9)
      }

      let!(:enrollment_11) {
        create_enrollment(family: employee_E.person.primary_family, benefit_group_assignment: employee_E.census_employee.active_benefit_group_assignment, status: 'coverage_enrolled', employee_role: employee_E, submitted_at: plan_year.open_enrollment_end_on - 1.day, effective_date: plan_year.start_on.next_month)
      }

      let!(:enrollment_12) {
        create_enrollment(family: employee_E.person.primary_family, benefit_group_assignment: employee_E.census_employee.active_benefit_group_assignment, employee_role: employee_E, submitted_at: quiet_period_end_date - 2.days, effective_date: plan_year.start_on.next_month)
      }

      let!(:enrollment_13) {
        create_enrollment(family: employee_E.person.primary_family, benefit_group_assignment: employee_E.census_employee.active_benefit_group_assignment, coverage_kind: 'dental', employee_role: employee_E, submitted_at: plan_year.open_enrollment_end_on - 1.day, effective_date: plan_year.start_on.next_month)
      }

      let!(:enrollment_14) {
        create_enrollment(family: employee_E.person.primary_family, benefit_group_assignment: employee_E.census_employee.active_benefit_group_assignment, coverage_kind: 'dental', employee_role: employee_E, submitted_at: quiet_period_end_date - 2.days, effective_date: plan_year.start_on.next_month)
      }

      let!(:enrollment_15) {
        create_enrollment(family: employee_E.person.primary_family, benefit_group_assignment: employee_E.census_employee.active_benefit_group_assignment, employee_role: employee_E, submitted_at: plan_year.open_enrollment_end_on - 1.day, effective_date: plan_year.start_on)
      }

      let!(:enrollment_16) {
        create_enrollment(family: employee_E.person.primary_family, benefit_group_assignment: employee_E.census_employee.active_benefit_group_assignment, employee_role: employee_E, submitted_at: plan_year.open_enrollment_end_on + 3.day, effective_date: plan_year.start_on)
      }

      it "does not include enrollment 1" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).not_to include(enrollment_1.hbx_id)
      end

      it "includes enrollment 2" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_2.hbx_id)
      end

      it "does not include enrollment 3" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).not_to include(enrollment_3.hbx_id)
      end

      it "includes enrollment 4" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_4.hbx_id)
      end

      it "includes enrollment 5" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_5.hbx_id)
      end

      it "does not include enrollment 6" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).not_to include(enrollment_6.hbx_id)
      end

      it "includes enrollment 7" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_7.hbx_id)
      end

      it "includes enrollment 8" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_canceled', 'coverage_terminated', 'coverage_termination_pending'])
        expect(result).to include(enrollment_8.hbx_id)
      end

      it "includes enrollment 9" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_canceled', 'coverage_terminated', 'coverage_termination_pending'])
        expect(result).to include(enrollment_9.hbx_id)
      end

      it "does not include enrollment 10" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_canceled', 'coverage_terminated', 'coverage_termination_pending'])
        expect(result).not_to include(enrollment_10.hbx_id)
      end

      it "includes enrollment 10" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_10.hbx_id)
      end

      it "includes enrollment 11" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_enrolled'])
        expect(result).to include(enrollment_11.hbx_id)
      end

      it "includes enrollment 12" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_12.hbx_id)
      end

      it "includes enrollment 13" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_13.hbx_id)
      end

      it "includes enrollment 14" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_14.hbx_id)
      end

      it "does not includes enrollment 15" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).not_to include(enrollment_15.hbx_id)
      end

      context "enrollment with renewal application" do

        before do
          plan_year.predecessor_id = BSON::ObjectId.new
          plan_year.save
        end

        it "does not includes enrollment 16" do
          result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
          expect(result).not_to include(enrollment_16.hbx_id)
        end

      end
    end

    describe "with employees who have made the following plan terminations:
       - employee A has purchased:
         - One health enrollment during OE (Enrollment 1)
       - employee B has purchased:
         - One health enrollment during Quiet Period(Enrollment 2)
         - One health waiver during Quiet Period(Enrollment 3)
       - employee C has purchased:
         - One health enrollment during OE(Enrollment 4)
         - One dental enrollment during OE(Enrollment 5)
         - One health waiver during Quiet Period(Enrollment 6)
         - One dental waiver during Quiet Period(Enrollment 7)
         - Then another health enrollment outside Quiet Period(Enrollment 8)
         - Then another dental enrollment outside Quiet Period(Enrollment 9)
    " ,dbclean: :after_each do


      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"
      include_context "setup employees"

      let(:product_kinds)  { [:health, :dental] }
      let(:dental_sponsored_benefit) { true }

      let(:current_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
      let(:effective_on) { current_effective_date }
      let(:aasm_state) { :active }

      let(:initial_employer) {
        abc_profile
      }

      let(:plan_year) {
        initial_application
      }

      let(:quiet_period_end_on) {
        Settings.aca.shop_market.initial_application.quiet_period.mday
      }

      let(:quiet_period_end_date) {
        plan_year.start_on + (Settings.aca.shop_market.initial_application.quiet_period.month_offset).months + (Settings.aca.shop_market.initial_application.quiet_period.mday-1).days
      }


      let(:initial_employees) {
        census_employees
      }


      let(:employee_A) {
        ce = initial_employees[0]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_1) {
        create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: plan_year.open_enrollment_end_on - 10.day)
      }



      let(:employee_B) {
        ce = initial_employees[1]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_2) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: quiet_period_end_date.prev_day)
      }

      let!(:enrollment_3) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: quiet_period_end_date.prev_day, status: 'inactive', parent: enrollment_2)
      }

      let(:employee_C) {
        ce = initial_employees[2]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_4) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: plan_year.open_enrollment_end_on - 10.day)
      }

      let!(:enrollment_5) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: plan_year.open_enrollment_end_on - 10.day, coverage_kind: 'dental')
      }

      let!(:enrollment_6) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.prev_day, status: 'inactive', parent: enrollment_4)
      }

      let!(:enrollment_7) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.prev_day, coverage_kind: 'dental', status: 'inactive', parent: enrollment_5)
      }

      let!(:enrollment_8) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.next_day)
      }

      let!(:enrollment_9) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.next_day, coverage_kind: 'dental')
      }

      let(:term_statuses){ %w(coverage_terminated coverage_canceled coverage_termination_pending) }


      it "does not include enrollment 1" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, [])
        expect(result).not_to include(enrollment_1.hbx_id)
      end

      it "includes enrollment 2" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).to include(enrollment_2.hbx_id)
      end

      it "does not include enrollment 3" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_3.hbx_id)
      end

      it "includes enrollment 4" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).to include(enrollment_4.hbx_id)
      end

      it "includes enrollment 5" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).to include(enrollment_5.hbx_id)
      end

      it "does not include enrollment 6" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_6.hbx_id)
      end

      it "does not include enrollment 7" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_7.hbx_id)
      end

      it "does not include enrollment 8" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_8.hbx_id)
      end

      it "does not include enrollment 9" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_9.hbx_id)
      end
    end

    describe '.queit_period' do
      let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }

      it 'should be in exchange local time' do
        qs = Queries::ShopMonthlyEnrollments.new([], effective_on)
        expect(qs.quiet_period.begin.in_time_zone(TimeKeeper.exchange_zone).strftime("%H:%M")).to eq ("00:00")
        expect(qs.quiet_period.end.in_time_zone(TimeKeeper.exchange_zone).strftime("%H:%M")).to eq ("00:00")
      end
    end
  end

  def create_person(ce, employer_profile)
    person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
    employee_role
  end

  def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil, coverage_kind: 'health', parent: nil)
    benefit_group = benefit_group_assignment.benefit_group
    sponsored_benefit = benefit_group.sponsored_benefit_for(coverage_kind)
    enrollment = FactoryBot.create(:hbx_enrollment,:with_enrollment_members,
      enrollment_members: [family.primary_applicant],
      household: family.active_household,
      coverage_kind: coverage_kind,
      family: family,
      effective_on: effective_date || benefit_group.start_on,
      enrollment_kind: enrollment_kind,
      kind: "employer_sponsored",
      submitted_at: submitted_at,
      benefit_sponsorship_id: benefit_group.benefit_sponsorship.id,
      sponsored_benefit_package_id: benefit_group.id,
      sponsored_benefit_id: sponsored_benefit.id,
      employee_role_id: employee_role.id,
      benefit_group_assignment_id: benefit_group_assignment.id,
      plan_id: sponsored_benefit.reference_product.id,
      aasm_state: status
    )

    if enrollment.coverage_selected? || enrollment.inactive?
      enrollment.workflow_state_transitions.create(from_state: 'shopping', to_state: status, transition_at: submitted_at)
    end

    if (enrollment.inactive? || enrollment.coverage_selected?) && parent.present?
      parent.update(aasm_state: 'coverage_canceled')
      parent.workflow_state_transitions.create(from_state: parent.aasm_state, to_state: 'coverage_canceled', transition_at: submitted_at)
    end

    enrollment
  end
end

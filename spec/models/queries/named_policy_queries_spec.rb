require "rails_helper"

describe Queries::NamedPolicyQueries, "Policy Queries", dbclean: :after_each do

  context "Shop Monthly Queries" do

    let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }

    let(:initial_employer) {
      FactoryGirl.create(:employer_with_planyear, start_on: effective_on, plan_year_state: 'enrolled')
    }

    let(:initial_employees) {
      FactoryGirl.create_list(:census_employee_with_active_assignment, 5, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: initial_employer,
        benefit_group: initial_employer.published_plan_year.benefit_groups.first,
        created_at: TimeKeeper.date_of_record.prev_year)
    }

    let(:renewing_employer) {
      FactoryGirl.create(:employer_with_renewing_planyear, start_on: effective_on, renewal_plan_year_state: 'renewing_enrolled')
    }

    let(:renewing_employees) {
      FactoryGirl.create_list(:census_employee_with_active_and_renewal_assignment, 5, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: renewing_employer,
        benefit_group: renewing_employer.active_plan_year.benefit_groups.first,
        renewal_benefit_group: renewing_employer.renewing_plan_year.benefit_groups.first,
        created_at: TimeKeeper.date_of_record.prev_year)
    }

    let!(:initial_employee_enrollments) {
      initial_employees.inject([]) do |enrollments, ce|
        employee_role = create_person(ce, initial_employer)
        enrollments << create_enrollment(family: employee_role.person.primary_family, benefit_group_assignment: ce.active_benefit_group_assignment, employee_role: employee_role, submitted_at: effective_on - 20.days)
      end
    }

    let!(:renewing_employee_enrollments) {
      renewing_employees.inject([]) do |enrollments, ce|
        employee_role = create_person(ce, renewing_employer)
        enrollments << create_enrollment(family: employee_role.person.primary_family, benefit_group_assignment: ce.active_benefit_group_assignment, employee_role: employee_role, submitted_at: effective_on - 20.days)
        enrollments << create_enrollment(family: employee_role.person.primary_family, benefit_group_assignment: ce.renewal_benefit_group_assignment, employee_role: employee_role, status: 'auto_renewing', submitted_at: effective_on - 20.days)
      end
    }

    let(:renewing_employee_passives) {
      renewing_employee_enrollments.select{|e| e.auto_renewing?}
    }

    let(:feins) {
      [initial_employer.fein, renewing_employer.fein]
    }

    def create_person(ce, employer_profile)
      person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
      employee_role
    end

    def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil)
       benefit_group = benefit_group_assignment.benefit_group
       FactoryGirl.create(:hbx_enrollment,:with_enrollment_members,
          enrollment_members: [family.primary_applicant],
          household: family.active_household,
          coverage_kind: "health",
          effective_on: effective_date || benefit_group.start_on,
          enrollment_kind: enrollment_kind,
          kind: "employer_sponsored",
          submitted_at: submitted_at,
          benefit_group_id: benefit_group.id,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: benefit_group_assignment.id,
          plan_id: benefit_group.reference_plan.id,
          aasm_state: status
        )
    end

    context ".shop_monthly_enrollments" do

      context 'When passed employer FEINs and plan year effective date' do

        it 'should return coverages under given employers' do
          enrollment_hbx_ids = (initial_employee_enrollments + renewing_employee_passives).map(&:hbx_id)
          result = Queries::NamedPolicyQueries.shop_monthly_enrollments(feins, effective_on)

          expect(result.sort).to eq enrollment_hbx_ids.sort
        end

        context 'When enrollments purchased with QLE' do

          let!(:qle_coverages) {
            renewing_employees[0..4].inject([]) do |enrollments, ce|
              family = ce.employee_role.person.primary_family
              enrollments << create_enrollment(family: family, benefit_group_assignment: ce.renewal_benefit_group_assignment, employee_role: ce.employee_role, submitted_at: effective_on - 10.days, enrollment_kind: 'special_enrollment')
            end
          }

          it 'should not return QLE enrollments' do
            result = Queries::NamedPolicyQueries.shop_monthly_enrollments(feins, effective_on)

            expect(result & qle_coverages.map(&:hbx_id)).to eq []
          end
        end

        context 'When both active and passive renewal present' do

          let!(:actively_renewed_coverages) {
            renewing_employees[0..4].inject([]) do |enrollments, ce|
              enrollments << create_enrollment(family: ce.employee_role.person.primary_family, benefit_group_assignment: ce.renewal_benefit_group_assignment, employee_role: ce.employee_role, submitted_at: effective_on - 10.days)
            end
          }

          it 'should return active renewal' do
            active_renewal_hbx_ids = actively_renewed_coverages.map(&:hbx_id).sort
            result = Queries::NamedPolicyQueries.shop_monthly_enrollments(feins, effective_on)
            expect(result.sort & active_renewal_hbx_ids).to eq active_renewal_hbx_ids
          end
        end
      end
    end

    context '.shop_monthly_terminations' do
      context 'When passed employer FEINs and plan year effective date' do

        context 'When EE created waivers' do

          let!(:active_waivers) {
            renewing_employees[0..4].inject([]) do |enrollments, ce|
              enrollment= create_enrollment(family: ce.employee_role.person.primary_family, benefit_group_assignment: ce.renewal_benefit_group_assignment, employee_role: ce.employee_role, submitted_at: effective_on - 10.days, status: 'shopping')
              enrollment.waive_coverage!
              enrollments << enrollment
            end
          }

          it 'should return their previous enrollments as terminations' do
            termed_enrollments = active_waivers.collect{|en| en.family.active_household.hbx_enrollments.where(:effective_on => effective_on.prev_year).first}
            result = Queries::NamedPolicyQueries.shop_monthly_terminations(feins, effective_on)
            expect(result.sort).to eq termed_enrollments.map(&:hbx_id).sort
          end
        end
      end
    end
  end
end

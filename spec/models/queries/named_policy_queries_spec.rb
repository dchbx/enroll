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
        enrollments << create_enrollment(family: employee_role.person.primary_family, benefit_group_assignment: ce.active_benefit_group_assignment, employee_role: employee_role, submitted_at: effective_on.prev_month)
      end
    }
    
    let!(:cobra_employees) {
      FactoryGirl.create_list(:census_employee_with_active_and_renewal_assignment, 5, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: renewing_employer,
                              benefit_group: renewing_employer.active_plan_year.benefit_groups.first,
                              renewal_benefit_group: renewing_employer.renewing_plan_year.benefit_groups.first,
                              created_at: TimeKeeper.date_of_record.prev_year)
    }

    let(:updating_cobra_employees) {cobra_employees.each do |employee|
      employee.aasm_state='cobra_linked'
      employee.cobra_begin_date=TimeKeeper.date_of_record.end_of_month
      employee.save
    end}

    let!(:cobra_employee_enrollments) {
      cobra_employees.inject([]) do |enrollments, ce|
        employee_role = create_person(ce, renewing_employer)
        enrollments << create_enrollment(family: employee_role.person.primary_family, kind:"employer_sponsored",benefit_group_assignment: ce.renewal_benefit_group_assignment, employee_role: employee_role, status: 'terminated')
        enrollments << create_enrollment(family: employee_role.person.primary_family, kind:"employer_sponsored_cobra",benefit_group_assignment: ce.renewal_benefit_group_assignment, employee_role: employee_role, status: 'auto_renewing', submitted_at: effective_on - 20.days)
      end
    }

    let!(:initial_employee_quiet_enrollments) {
      initial_employees.inject([]) do |enrollments, ce|
        employee_role = create_person(ce, initial_employer)
        enrollments << create_enrollment(family: employee_role.person.primary_family, benefit_group_assignment: ce.active_benefit_group_assignment, employee_role: employee_role, submitted_at: (ce.active_benefit_group_assignment.plan_year.start_on + (Settings.aca.shop_market.initial_application.quiet_period.month_offset).months + Settings.aca.shop_market.initial_application.quiet_period.mday- 1.days))
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

    let(:cobra_enrollments) {
      cobra_employee_enrollments.select{|e| e.is_cobra_status?}
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

    def create_enrollment(family: nil, benefit_group_assignment: nil, kind:"employer_sponsored",employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil)
       benefit_group = benefit_group_assignment.benefit_group
       FactoryGirl.create(:hbx_enrollment,:with_enrollment_members,
          enrollment_members: [family.primary_applicant],
          household: family.active_household,
          coverage_kind: "health",
          effective_on: effective_date || benefit_group.start_on,
          enrollment_kind: enrollment_kind,
          kind: kind,
          submitted_at: submitted_at,
          benefit_group_id: benefit_group.id,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: benefit_group_assignment.id,
          plan_id: benefit_group.reference_plan.id,
          aasm_state: status
        )
    end

    context ".shop_monthly_enrollments", dbclean: :after_each do

      context 'When passed employer FEINs and plan year effective date', dbclean: :after_each do

        it 'should return coverages under given employers that includes initial, renewal & cobra enrollments' do
          enrollment_hbx_ids = (initial_employee_enrollments + renewing_employee_passives + cobra_enrollments).map(&:hbx_id)
          result = Queries::NamedPolicyQueries.shop_monthly_enrollments(feins, effective_on)

          expect(result.sort).to eq enrollment_hbx_ids.sort
        end

        it 'should not return coverages under given employers if they are in quiet period' do
          quiet_enrollment_hbx_ids = (initial_employee_quiet_enrollments).map(&:hbx_id)
          result = Queries::NamedPolicyQueries.shop_monthly_enrollments(feins, effective_on)
          expect(result & quiet_enrollment_hbx_ids).to eq []
        end

        context 'When renewal enrollments purchased with QLE and not in quiet period' do

          let(:qle_coverages) {
            renewing_employees[0..4].inject([]) do |enrollments, ce|
              family = ce.employee_role.person.primary_family
              enrollments << create_enrollment(family: family, benefit_group_assignment: ce.renewal_benefit_group_assignment, employee_role: ce.employee_role, submitted_at: effective_on - 1.month + 8.days, enrollment_kind: 'special_enrollment')
            end
          }

          before do
            renewing_employees[0..4].each do |ce|
              ce.employee_role.person.primary_family.active_household.hbx_enrollments.each { |enr| enr.cancel_coverage! }
            end

            qle_coverages
          end

          it 'should return QLE enrollments' do
            result = Queries::NamedPolicyQueries.shop_monthly_enrollments(feins, effective_on)
            expect((result & qle_coverages.map(&:hbx_id)).sort).to eq qle_coverages.map(&:hbx_id).sort
          end
        end

        context 'When renewal enrollments purchased with QLE and submitted before the drop date' do
          let(:qle_coverages_in_quiet_period) {
            renewing_employees[0..4].inject([]) do |enrollments, ce|
              family = ce.employee_role.person.primary_family
              enrollments << create_enrollment(family: family, benefit_group_assignment: ce.renewal_benefit_group_assignment, employee_role: ce.employee_role, submitted_at: (ce.renewal_benefit_group_assignment.plan_year.start_on.prev_month + Settings.aca.shop_market.renewal_application.quiet_period.mday + 2.days), enrollment_kind: 'special_enrollment')
            end
          }

          before do
            renewing_employees[0..4].each do |ce|
              ce.employee_role.person.primary_family.active_household.hbx_enrollments.each { |enr| enr.cancel_coverage! }
            end

            qle_coverages_in_quiet_period
          end

          it 'should return QLE enrollments' do
            result = Queries::NamedPolicyQueries.shop_monthly_enrollments(feins, effective_on)
            expect((result & qle_coverages_in_quiet_period.map(&:hbx_id)).sort).to eq []
          end
        end

        context 'When both active and passive renewal present' do

          let(:actively_renewed_coverages) {
            renewing_employees[0..4].inject([]) do |enrollments, ce|
              enrollments << create_enrollment(family: ce.employee_role.person.primary_family, benefit_group_assignment: ce.renewal_benefit_group_assignment, employee_role: ce.employee_role, submitted_at: effective_on - 1.month + 8.days)
            end
          }

          before do
            renewing_employees[0..4].each do |ce|
              ce.employee_role.person.primary_family.active_household.hbx_enrollments.where(:"benefit_group_id".in => [ce.renewal_benefit_group_assignment.benefit_group_id]).each { |enr| enr.cancel_coverage! }
            end
          end

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

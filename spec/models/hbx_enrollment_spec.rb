require 'rails_helper'
require 'aasm/rspec'

describe HbxEnrollment do

  context "an employer defines a plan year with multiple benefit groups, adds employees to roster and assigns benefit groups" do
    let(:blue_collar_employee_count)              { 7 }
    let(:white_collar_employee_count)             { 5 }
    let(:fte_count)                               { blue_collar_employee_count + white_collar_employee_count }
    let(:employer_profile)                        { FactoryGirl.create(:employer_profile) }

    let(:plan_year_start_on)                      { TimeKeeper.date_of_record.next_month.end_of_month + 1.day }
    let(:plan_year_end_on)                        { (plan_year_start_on + 1.year) - 1.day }

    let(:blue_collar_benefit_group)               { plan_year.benefit_groups[0] }
    def blue_collar_benefit_group_assignment
      BenefitGroupAssignment.new(benefit_group: blue_collar_benefit_group, start_on: plan_year_start_on )
    end

    let(:white_collar_benefit_group)              { plan_year.benefit_groups[1] }
    def white_collar_benefit_group_assignment
      BenefitGroupAssignment.new(benefit_group: white_collar_benefit_group, start_on: plan_year_start_on )
    end

    before do
      allow(Settings).to receive(:aca).and_call_original
      allow(Settings).to receive_message_chain(:aca, :use_simple_employer_calculation_model).and_return(true)

      allow(Caches::PlanDetails).to receive(:lookup_rate) {|id, start, age| age * 1.0}
    end

    let(:all_benefit_group_assignments)           { [blue_collar_census_employees, white_collar_census_employees].flat_map do |census_employees|
                                                      census_employees.flat_map(&:benefit_group_assignments)
                                                    end
                                                    }

    let!(:plan_year)                               { py = FactoryGirl.create(:plan_year,
                                                                             start_on: plan_year_start_on,
                                                                             end_on: plan_year_end_on,
                                                                             open_enrollment_start_on: TimeKeeper.date_of_record,
                                                                             open_enrollment_end_on: TimeKeeper.date_of_record + 5.days,
                                                                             employer_profile: employer_profile
                                                                             )
                                                     blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
                                                     white = FactoryGirl.build(:benefit_group, title: "white collar", plan_year: py)

                                                     py.benefit_groups = [blue, white]
                                                     py.save
                                                     py.publish!
                                                     py
                                                     }
    let!(:blue_collar_census_employees)            { ees = FactoryGirl.create_list(:census_employee, blue_collar_employee_count, employer_profile: employer_profile)
                                                     ees.each() do |ee|
                                                       ee.benefit_group_assignments = [blue_collar_benefit_group_assignment]
                                                       ee.save
                                                     end
                                                     ees
                                                     }
    let!(:white_collar_census_employees)           { ees = FactoryGirl.create_list(:census_employee, white_collar_employee_count, employer_profile: employer_profile)
                                                     ees.each() do |ee|
                                                       ee.benefit_group_assignments = [white_collar_benefit_group_assignment]
                                                       ee.save
                                                     end
                                                     ees
                                                     }

    it "should have a valid plan year in enrolling state" do
      expect(plan_year.aasm_state).to eq "enrolling"
    end

    it "should have a roster with all blue and white collar employees" do
      expect(employer_profile.census_employees.size).to eq fte_count
    end

    context "and employees create employee roles and families" do
      let(:blue_collar_employee_roles) do
        bc_employees = blue_collar_census_employees.collect do |census_employee|
          person = Person.create!(
            first_name: census_employee.first_name,
            last_name: census_employee.last_name,
            ssn: census_employee.ssn,
            dob: census_employee.dob,
            gender: "male"
          )
          employee_role = person.employee_roles.build(
            employer_profile: census_employee.employer_profile,
            census_employee: census_employee,
            hired_on: census_employee.hired_on
          )

          census_employee.employee_role = employee_role
          census_employee.save!
          employee_role
        end
        bc_employees
      end

      let(:white_collar_employee_roles) do
        wc_employees = white_collar_census_employees.collect do |census_employee|
          person = Person.create!(
            first_name: census_employee.first_name,
            last_name: census_employee.last_name,
            ssn: census_employee.ssn,
            # ssn: (census_employee.ssn.to_i + 20).to_s,
            dob: census_employee.dob,
            gender: "male"
          )
          employee_role = person.employee_roles.build(
            employer_profile: census_employee.employer_profile,
            census_employee: census_employee,
            hired_on: census_employee.hired_on
          )

          census_employee.employee_role = employee_role
          census_employee.save!
          employee_role
        end
        wc_employees
      end

      let(:blue_collar_families) do
        blue_collar_employee_roles.reduce([]) { |list, employee_role| family = Family.find_or_build_from_employee_role(employee_role); list << family }
      end

      let(:white_collar_families) do
        white_collar_employee_roles.reduce([]) { |list, employee_role| family = Family.find_or_build_from_employee_role(employee_role); list << family }
      end

      it "should include the requisite blue collar employee roles and families" do
        expect(blue_collar_employee_roles.size).to eq blue_collar_employee_count
        expect(blue_collar_families.size).to eq blue_collar_employee_count
      end

      it "should include the requisite white collar employee roles and families" do
        expect(white_collar_employee_roles.size).to eq white_collar_employee_count
        expect(white_collar_families.size).to eq white_collar_employee_count
      end

      context "scope" do

        before do
          TimeKeeper.set_date_of_record_unprotected!(Date.new(2015,12,15))
        end

        after do
          TimeKeeper.set_date_of_record_unprotected!(Date.today)
        end

        it "with current year" do
          family = blue_collar_families.first
          employee_role = family.primary_family_member.person.employee_roles.first
          enrollment = HbxEnrollment.create_from(
            employee_role: employee_role,
            coverage_household: family.households.first.coverage_households.first,
            benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
            benefit_group: employee_role.census_employee.active_benefit_group_assignment.benefit_group,
          )
          enrollment.update(effective_on: Date.new(2015, 9, 12))

          enrollments = family.households.first.coverage_households.first.household.hbx_enrollments
          expect(enrollments.current_year).to eq [enrollment]
        end

      end

      context "and families either select plan or waive coverage" do
        let!(:blue_collar_enrollment_waivers) do
          family = blue_collar_families.first
          employee_role = family.primary_family_member.person.employee_roles.first
          election = HbxEnrollment.create_from(
            employee_role: employee_role,
            coverage_household: family.households.first.coverage_households.first,
            benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
            benefit_group: employee_role.census_employee.active_benefit_group_assignment.benefit_group
          )
          election.waiver_reason = HbxEnrollment::WAIVER_REASONS.first
          election.waive_coverage
          election.household.family.save!
          election.save!
          election.to_a
        end

        let!(:blue_collar_enrollments) do
          enrollments = blue_collar_families[1..(blue_collar_employee_count - 1)].collect do |family|
            employee_role = family.primary_family_member.person.employee_roles.first
            benefit_group = employee_role.census_employee.active_benefit_group_assignment.benefit_group
            election = HbxEnrollment.create_from(
              employee_role: employee_role,
              coverage_household: family.households.first.coverage_households.first,
              benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
              benefit_group: benefit_group
            )
            election.plan = benefit_group.elected_plans.sample
            election.select_coverage if election.can_complete_shopping?
            election.household.family.save!
            election.save!
            election
          end
          enrollments
        end

        let!(:white_collar_enrollment_waivers) do
          white_collar_families[0..1].collect do |family|
            employee_role = family.primary_family_member.person.employee_roles.first
            election = HbxEnrollment.create_from(
              employee_role: employee_role,
              coverage_household: family.households.first.coverage_households.first,
              benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
              benefit_group: employee_role.census_employee.active_benefit_group_assignment.benefit_group
            )
            election.waiver_reason = HbxEnrollment::WAIVER_REASONS.first
            election.waive_coverage
            election.household.family.save!
            election.save!
            election
          end
        end

        let!(:white_collar_enrollments) do
          white_collar_families[-3..-1].collect do |family|
            employee_role = family.primary_family_member.person.employee_roles.first
            benefit_group = employee_role.census_employee.active_benefit_group_assignment.benefit_group
            election = HbxEnrollment.create_from(
              employee_role: employee_role,
              coverage_household: family.households.first.coverage_households.first,
              benefit_group_assignment: employee_role.census_employee.active_benefit_group_assignment,
              benefit_group: benefit_group
            )
            election.plan = benefit_group.elected_plans.sample
            election.select_coverage if election.can_complete_shopping?
            election.household.family.save!
            election.save!
            election
          end
        end

        it "should find all employees who have waived or selected plans" do
          enrollments = HbxEnrollment.find_by_benefit_groups(all_benefit_group_assignments.collect(&:benefit_group))
          active_enrolled_enrollments = (blue_collar_enrollment_waivers + white_collar_enrollment_waivers + blue_collar_enrollments + white_collar_enrollments).reject{|e| !HbxEnrollment::ENROLLED_STATUSES.include?(e.aasm_state)}
          expect(enrollments.size).to eq (active_enrolled_enrollments.size)
          expect(enrollments).to match_array(active_enrolled_enrollments)
        end

        it "should know the total premium" do
          Caches::PlanDetails.load_record_cache!
          expect(blue_collar_enrollments.first.total_premium).to be
        end

        it "should know the total employee cost" do
          Caches::PlanDetails.load_record_cache!
          expect(blue_collar_enrollments.first.total_employee_cost).to be
        end

        it "should know the total employer contribution" do
          Caches::PlanDetails.load_record_cache!
          expect(blue_collar_enrollments.first.total_employer_contribution).to be
        end
      end

    end
  end
end

describe HbxEnrollment, dbclean: :after_all do
  include_context "BradyWorkAfterAll"

  before :all do
    create_brady_census_families
  end

  context "is created from an employer_profile, benefit_group, and coverage_household" do
    attr_reader :enrollment, :household, :coverage_household
    before :all do
      @household = mikes_family.households.first
      @coverage_household = household.coverage_households.first
      @enrollment = household.create_hbx_enrollment_from(
        employee_role: mikes_employee_role,
        coverage_household: coverage_household,
        benefit_group: mikes_benefit_group,
        benefit_group_assignment: @mikes_benefit_group_assignments
      )
    end

    it "should assign the benefit group assignment" do
      expect(enrollment.benefit_group_assignment_id).not_to be_nil
    end

    it "should be employer sponsored" do
      expect(enrollment.kind).to eq "employer_sponsored"
    end

    it "should set the employer_profile" do
      expect(enrollment.employer_profile._id).to eq mikes_employer._id
    end

    it "should be active" do
      expect(enrollment.is_active?).to be_truthy
    end

    it "should be effective when the plan_year starts by default" do
      expect(enrollment.effective_on).to eq mikes_plan_year.start_on
    end

    it "should be valid" do
      expect(enrollment.valid?).to be_truthy
    end

    it "should default to enrolling everyone" do
      expect(enrollment.applicant_ids).to match_array(coverage_household.applicant_ids)
    end

    it "should not return a total premium" do
      expect{enrollment.total_premium}.not_to raise_error
    end

    it "should not return an employee cost" do
      expect{enrollment.total_employee_cost}.not_to raise_error
    end

    it "should not return an employer contribution" do
      expect{enrollment.total_employer_contribution}.not_to raise_error
    end

    context "and the employee enrolls" do
      before :all do
        enrollment.plan = enrollment.benefit_group.reference_plan
        enrollment.save
      end

      it "should return a total premium" do
        Caches::PlanDetails.load_record_cache!
        expect(enrollment.total_premium).to be
      end

      it "should return an employee cost" do
        Caches::PlanDetails.load_record_cache!
        expect(enrollment.total_employee_cost).to be
      end

      it "should return an employer contribution" do
        Caches::PlanDetails.load_record_cache!
        expect(enrollment.total_employer_contribution).to be
      end
    end

    context "update_current" do
      before :all do
        @enrollment2 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments
        )
        @enrollment2.save
        @enrollment2.update_current(is_active: false)
      end

      it "enrollment and enrollment2 should have same household" do
        expect(@enrollment2.household).to eq enrollment.household
      end

      it "enrollment2 should be not active" do
        expect(@enrollment2.is_active).to  be_falsey
      end

      it "enrollment should be active" do
        expect(enrollment.is_active).to be_truthy
      end
    end

    context "inactive_related_hbxs" do
      before :all do
        @enrollment3 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments
        )
        @enrollment3.save
        @enrollment3.inactive_related_hbxs
      end

      it "should have an assigned hbx_id" do
        expect(@enrollment3.hbx_id).not_to eq nil
      end

      it "enrollment and enrollment3 should have same household" do
        expect(@enrollment3.household).to eq enrollment.household
      end

      it "enrollment should be not active" do
        expect(enrollment.is_active).to  be_falsey
      end

      it "enrollment3 should be active" do
        expect(@enrollment3.is_active).to be_truthy
      end

      it "should only one active when they have same employer" do
        hbxs = @enrollment3.household.hbx_enrollments.select do |hbx|
          hbx.employee_role.employer_profile_id == @enrollment3.employee_role.employer_profile_id and hbx.is_active?
        end
        expect(hbxs.count).to eq 1
      end
    end

    context "waive_coverage_by_benefit_group_assignment" do
      before :each do
        @enrollment4 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments
        )
        allow(@enrollment4).to receive(:notify_on_save).and_return true
        @enrollment4.save
        @enrollment5 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments

        )
        allow(@enrollment5).to receive(:notify_on_save).and_return true
        @enrollment5.save
        @enrollment4.waive_coverage_by_benefit_group_assignment("start a new job")
        @enrollment5.reload
      end

      it "enrollment4 should be inactive" do
        expect(@enrollment4.aasm_state).to eq "inactive"
      end

      it "enrollment4 should get waiver_reason" do
        expect(@enrollment4.waiver_reason).to eq "start a new job"
      end

      it "enrollment5 should not be waived" do
        expect(@enrollment5.aasm_state).to eq "shopping"
      end

      it "enrollment5 should not have waiver_reason" do
        expect(@enrollment5.waiver_reason).to eq nil
      end
    end

    context "should shedule termination previous auto renewing enrollment" do
      before :each do
        @enrollment6 = household.create_hbx_enrollment_from(
            employee_role: mikes_employee_role,
            coverage_household: coverage_household,
            benefit_group: mikes_benefit_group,
            benefit_group_assignment: @mikes_benefit_group_assignments
        )
        @enrollment6.effective_on=TimeKeeper.date_of_record + 1.days
        @enrollment6.aasm_state = "auto_renewing"
        allow(@enrollment6).to receive(:notify_on_save).and_return true
        @enrollment6.save
        @enrollment7 = household.create_hbx_enrollment_from(
            employee_role: mikes_employee_role,
            coverage_household: coverage_household,
            benefit_group: mikes_benefit_group,
            benefit_group_assignment: @mikes_benefit_group_assignments
        )
        allow(@enrollment7).to receive(:notify_on_save).and_return true
        @enrollment7.save
        @enrollment7.cancel_previous(TimeKeeper.date_of_record.year)
      end

      it "doesn't move enrollment for shop market" do
        expect(@enrollment6.aasm_state).to eq "auto_renewing"
      end

      it "should not cancel current shopping enrollment" do
        expect(@enrollment7.aasm_state).to eq "shopping"
      end
    end

    context "decorated_elected_plans" do
      let(:benefit_package) { BenefitPackage.new }
      let(:consumer_role) { FactoryGirl.create(:consumer_role) }
      let(:person) { double(primary_family: family)}
      let(:family) { double }
      let(:enrollment) {
        enrollment = household.new_hbx_enrollment_from(
          consumer_role: consumer_role,
          coverage_household: coverage_household,
          benefit_package: benefit_package,
          qle: true
        )
        enrollment.save
        enrollment
      }
      let(:hbx_profile) {double}
      let(:benefit_sponsorship) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, renewal_benefit_coverage_period: renewal_bcp, current_benefit_coverage_period: bcp) }
      let(:renewal_bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months) }
      let(:bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months) }
      let(:plan) { FactoryGirl.create(:plan) }
      let(:plan2) { FactoryGirl.create(:plan) }

      context "when in open enrollment" do
        before :each do
          allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
          allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
          allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
          allow(consumer_role).to receive(:person).and_return(person)
          allow(coverage_household).to receive(:household).and_return household
          allow(household).to receive(:family).and_return family
          allow(family).to receive(:is_under_special_enrollment_period?).and_return false
          allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
          allow(enrollment).to receive(:enrollment_kind).and_return "open_enrollment"
        end

        it "should return decoratored plans when not in the open enrollment" do
          allow(renewal_bcp).to receive(:open_enrollment_contains?).and_return false
          allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
          allow(bcp).to receive(:elected_plans_by_enrollment_members).and_return [plan]
          expect(enrollment.decorated_elected_plans('health').first.class).to eq UnassistedPlanCostDecorator
          expect(enrollment.decorated_elected_plans('health').count).to eq 1
          expect(enrollment.decorated_elected_plans('health').first.id).to eq plan.id
        end

        it "should return decoratored plans when in the open enrollment" do
          allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(renewal_bcp)
          allow(renewal_bcp).to receive(:open_enrollment_contains?).and_return true
          allow(renewal_bcp).to receive(:elected_plans_by_enrollment_members).and_return [plan2]
          expect(enrollment.decorated_elected_plans('health').first.class).to eq UnassistedPlanCostDecorator
          expect(enrollment.decorated_elected_plans('health').count).to eq 1
          expect(enrollment.decorated_elected_plans('health').first.id).to eq plan2.id
        end
      end

      context "when in special enrollment" do
        let(:sep) {SpecialEnrollmentPeriod.new(effective_on: TimeKeeper.date_of_record)}
        before :each do
          allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
          allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
          allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
          allow(consumer_role).to receive(:person).and_return(person)
          allow(coverage_household).to receive(:household).and_return household
          allow(household).to receive(:family).and_return family
          allow(family).to receive(:current_sep).and_return sep
          allow(family).to receive(:current_special_enrollment_periods).and_return [sep]
          allow(family).to receive(:is_under_special_enrollment_period?).and_return true
          allow(enrollment).to receive(:enrollment_kind).and_return "special_enrollment"
        end

        it "should return decoratored plans when not in the open enrollment" do
          enrollment.update_attributes(effective_on: sep.effective_on - 1.month)
          allow(renewal_bcp).to receive(:open_enrollment_contains?).and_return false
          allow(benefit_sponsorship).to receive(:benefit_coverage_period_by_effective_date).with(enrollment.effective_on).and_return(bcp)
          allow(bcp).to receive(:elected_plans_by_enrollment_members).and_return [plan]
          expect(enrollment.decorated_elected_plans('health').first.class).to eq UnassistedPlanCostDecorator
          expect(enrollment.decorated_elected_plans('health').count).to eq 1
          expect(enrollment.decorated_elected_plans('health').first.id).to eq plan.id
          expect(enrollment.created_at).not_to be_nil
        end
      end
    end

    context "status_step" do
      let(:hbx_enrollment) { HbxEnrollment.new }

      it "return 1 when coverage_selected" do
        hbx_enrollment.aasm_state = "coverage_selected"
        expect(hbx_enrollment.status_step).to eq 1
      end

      it "return 2 when transmitted_to_carrier" do
        hbx_enrollment.aasm_state = "transmitted_to_carrier"
        expect(hbx_enrollment.status_step).to eq 2
      end

      it "return 3 when enrolled_contingent" do
        hbx_enrollment.aasm_state = "enrolled_contingent"
        expect(hbx_enrollment.status_step).to eq 3
      end

      it "return 4 when coverage_enrolled" do
        hbx_enrollment.aasm_state = "coverage_enrolled"
        expect(hbx_enrollment.status_step).to eq 4
      end

      it "return 5 when coverage_canceled" do
        hbx_enrollment.aasm_state = "coverage_canceled"
        expect(hbx_enrollment.status_step).to eq 5
      end

      it "return 5 when coverage_terminated" do
        hbx_enrollment.aasm_state = "coverage_terminated"
        expect(hbx_enrollment.status_step).to eq 5
      end
    end

    context "enrollment_kind" do
      let(:hbx_enrollment) { HbxEnrollment.new }
      it "should fail validation when blank" do
        hbx_enrollment.enrollment_kind = ""
        expect(hbx_enrollment.valid?).to eq false
        expect(hbx_enrollment.errors[:enrollment_kind].any?).to eq true
      end

      it "should fail validation when not in ENROLLMENT_KINDS" do
        hbx_enrollment.enrollment_kind = "test"
        expect(hbx_enrollment.valid?).to eq false
        expect(hbx_enrollment.errors[:enrollment_kind].any?).to eq true
      end

      it "is_open_enrollment?" do
        hbx_enrollment.enrollment_kind = "open_enrollment"
        expect(hbx_enrollment.is_open_enrollment?).to eq true
        expect(hbx_enrollment.is_special_enrollment?).to eq false
      end

      it "is_special_enrollment?" do
        hbx_enrollment.enrollment_kind = "special_enrollment"
        expect(hbx_enrollment.is_open_enrollment?).to eq false
        expect(hbx_enrollment.is_special_enrollment?).to eq true
      end
    end

    context "inactive_pre_hbx" do
      let(:consumer_role) {FactoryGirl.create(:consumer_role)}
      let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
      let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
      let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
      let(:hbx) {HbxEnrollment.new(consumer_role_id: consumer_role.id)}
      let(:family) {FactoryGirl.build(:family)}
      before :each do
        allow(benefit_coverage_period).to receive(:earliest_effective_date).and_return TimeKeeper.date_of_record
        allow(coverage_household).to receive(:household).and_return household
        allow(household).to receive(:family).and_return family
        allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
        @enrollment = household.create_hbx_enrollment_from(
          consumer_role: consumer_role,
          coverage_household: coverage_household,
          benefit_package: benefit_package
        )
        @enrollment.save
      end

      it "should have an assigned hbx_id" do
        hbx.inactive_pre_hbx(@enrollment.id)
        expect(@enrollment.hbx_id).not_to eq nil
      end

      it "should update pre_hbx status" do
        hbx.inactive_pre_hbx(@enrollment.id)
        @enrollment.reload
        expect(@enrollment.is_active).to eq false
      end
    end
  end

  context "#propogate_waiver", dbclean: :after_each do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:census_employee) { FactoryGirl.create(:census_employee)}
    let(:benefit_group_assignment) { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group)}
    let(:enrollment) { FactoryGirl.create(:hbx_enrollment, :individual_unassisted, household: family.active_household)}
    let(:enrollment_two) { FactoryGirl.create(:hbx_enrollment, :shop, household: family.active_household)}
    let(:enrollment_three) { FactoryGirl.create(:hbx_enrollment, :cobra_shop, household: family.active_household)}
    before do
      benefit_group_assignment.update_attribute(:hbx_enrollment_id, enrollment_two.id)
      enrollment_two.update_attributes(benefit_group_id: benefit_group_assignment.benefit_group.id, benefit_group_assignment_id: benefit_group_assignment.id)
    end
    it "should return false if it is an ivl enrollment" do
      expect(enrollment.propogate_waiver).to eq false
    end

    it "should return true for shop enrollment" do
      expect(enrollment_two.propogate_waiver).to eq true
    end

    it "should waive the benefit group assignment if enrollment belongs to health & shop" do
      enrollment_two.propogate_waiver
      expect(enrollment_two.benefit_group_assignment.aasm_state).to eq "coverage_waived"
    end

    it "should not waive the benefit group assignment if enrollment belongs to dental" do
      enrollment_two.update_attribute(:coverage_kind, "dental")
      enrollment_two.propogate_waiver
      expect(enrollment_two.benefit_group_assignment.aasm_state).not_to eq "coverage_waived"
    end

    it "should cancel the shop enrollment" do
      enrollment_two.propogate_waiver
      expect(enrollment_two.aasm_state).to eq "coverage_canceled"
    end
  end
end

describe HbxProfile, "class methods", type: :model do
  include_context "BradyWorkAfterAll"

  before :all do
    create_brady_census_families
  end

  context "#find" do
    it "should return nil with invalid id" do
      expect(HbxEnrollment.find("text")).to eq nil
    end
  end

  context "new_from" do
    attr_reader :household, :coverage_household
    before :all do
      @household = mikes_family.households.first
      @coverage_household = household.coverage_households.first
    end
    let(:benefit_package) { BenefitPackage.new }
    let(:consumer_role) { FactoryGirl.create(:consumer_role) }
    let(:person) { double(primary_family: family)}
    let(:family) { double(current_sep: double(effective_on:TimeKeeper.date_of_record)) }
    let(:hbx_profile) {double}
    let(:benefit_sponsorship) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, renewal_benefit_coverage_period: renewal_bcp, current_benefit_coverage_period: bcp) }
    let(:bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months) }
    let(:renewal_bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months) }

    before :each do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
      allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
      allow(consumer_role).to receive(:person).and_return(person)
      allow(household).to receive(:family).and_return family
      allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
    end

    shared_examples_for "new enrollment from" do |qle, sep, enrollment_period, error|
      context "#{enrollment_period} period" do
        let(:enrollment) { HbxEnrollment.new_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package, qle: qle) }
        before do
          allow(family).to receive(:is_under_special_enrollment_period?).and_return sep
          allow(family).to receive(:is_under_ivl_open_enrollment?).and_return enrollment_period == "open_enrollment"
        end

        unless error
          it "assigns #{enrollment_period} as enrollment_kind when qle is #{qle}" do
            expect(enrollment.enrollment_kind).to eq enrollment_period
          end
          it "should have submitted at as current date and time" do
            enrollment.save
            expect(enrollment.submitted_at).not_to be_nil
          end
          it "creates hbx_enrollment members " do
            expect(enrollment.hbx_enrollment_members).not_to be_empty
          end
          it "creates members with coverage_start_on as enrollment effective_on" do
            expect(enrollment.hbx_enrollment_members.first.coverage_start_on).to eq enrollment.effective_on
          end
        else
          it "raises an error" do
            expect{HbxEnrollment.new_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package, qle: false)}.to raise_error(RuntimeError)
          end
        end
      end
    end

    it_behaves_like "new enrollment from", false, true, "open_enrollment", false
    it_behaves_like "new enrollment from", true, true, "special_enrollment", false
    it_behaves_like "new enrollment from", false, false, "not_open_enrollment", "raise_an_error"
  end

  context "is reporting a qle before the employer plan start_date and having a expired plan year" do
    let(:coverage_household) { double}
    let(:coverage_household_members) {double}
    let(:household) {FactoryGirl.create(:household, family: family)}
    let(:qle_kind) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date) }
    let(:organization) { FactoryGirl.create(:organization, :with_expired_and_active_plan_years)}
    let(:census_employee) { FactoryGirl.create :census_employee, employer_profile: organization.employer_profile, dob: TimeKeeper.date_of_record - 30.years, first_name: person.first_name, last_name: person.last_name }
    let(:employee_role) { FactoryGirl.create(:employee_role, person: person, census_employee: census_employee, employer_profile: organization.employer_profile)}
    let(:person) { FactoryGirl.create(:person)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}
    let(:sep){
      sep = family.special_enrollment_periods.new
      sep.effective_on_kind = 'date_of_event'
      sep.qualifying_life_event_kind= qle_kind
      sep.qle_on= TimeKeeper.date_of_record - 7.days
      sep.start_on = sep.qle_on
      sep.end_on = sep.qle_on + 30.days
      sep.save
      sep
    }

    before do
      allow(coverage_household).to receive(:household).and_return family.active_household
      allow(coverage_household).to receive(:coverage_household_members).and_return []
      allow(sep).to receive(:is_active?).and_return true
      allow(family).to receive(:is_under_special_enrollment_period?).and_return true
      expired_py = organization.employer_profile.plan_years.where(aasm_state: 'expired').first
      census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: expired_py.benefit_groups[0], start_on: expired_py.benefit_groups[0].start_on)
      census_employee.update_attributes(:employee_role =>  employee_role, :employee_role_id =>  employee_role.id, hired_on: TimeKeeper.date_of_record - 2.months)
      census_employee.update_attribute(:ssn, census_employee.employee_role.person.ssn)
    end

    it "should return a sep with an effective date that equals to sep date" do
       enrollment = HbxEnrollment.new_from(employee_role: employee_role, coverage_household: coverage_household, benefit_group: nil, benefit_package: nil, benefit_group_assignment: nil, qle: true)
       expect(enrollment.effective_on).to eq sep.qle_on
    end
  end

  context "coverage_year" do
    let(:date){ TimeKeeper.date_of_record }
    let(:plan_year){ PlanYear.new(start_on: date) }
    let(:benefit_group){ BenefitGroup.new(plan_year: plan_year) }
    let(:plan){ Plan.new(active_year: date.year) }
    let(:hbx_enrollment){ HbxEnrollment.new(benefit_group: benefit_group, effective_on: date.end_of_year + 1.day, kind: "employer_sponsored", plan: plan) }

    before do
      allow(hbx_enrollment).to receive(:benefit_group).and_return(benefit_group)
    end

    it "should return plan year start on year when shop" do
      expect(hbx_enrollment.coverage_year).to eq date.year
    end

    it "should return plan year when ivl" do
      allow(hbx_enrollment).to receive(:kind).and_return("")
      expect(hbx_enrollment.coverage_year).to eq hbx_enrollment.plan.active_year
    end

    it "should return correct year when ivl" do
      allow(hbx_enrollment).to receive(:kind).and_return("")
      allow(hbx_enrollment).to receive(:plan).and_return(nil)
      expect(hbx_enrollment.coverage_year).to eq hbx_enrollment.effective_on.year
    end
  end

  context "calculate_effective_on_from" do
    let(:date) {TimeKeeper.date_of_record}
    let(:family) { double(current_sep: double(effective_on:date), is_under_special_enrollment_period?: true) }
    let(:hbx_profile) {double}
    let(:benefit_sponsorship) { double }
    let(:bcp) { double }
    let(:benefit_group) {double()}
    let(:employee_role) {double(hired_on: date)}

    before :each do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
      allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
    end

    context "shop" do
      it "special_enrollment" do
        expect(HbxEnrollment.calculate_effective_on_from(market_kind:'shop', qle:true, family: family, employee_role: nil, benefit_group: nil, benefit_sponsorship: nil)).to eq date
      end

      it "open_enrollment" do
        effective_on = date - 10.days
        allow(benefit_group).to receive(:effective_on_for).and_return(effective_on)
        allow(family).to receive(:is_under_special_enrollment_period?).and_return(false)
        expect(HbxEnrollment.calculate_effective_on_from(market_kind:'shop', qle:false, family: family, employee_role: employee_role, benefit_group: benefit_group, benefit_sponsorship: nil)).to eq effective_on
      end
    end

    context "individual" do
      it "special_enrollment" do
        expect(HbxEnrollment.calculate_effective_on_from(market_kind:'individual', qle:true, family: family, employee_role: nil, benefit_group: nil, benefit_sponsorship: nil)).to eq date
      end

      it "open_enrollment" do
        effective_on = date - 10.days
        allow(bcp).to receive(:earliest_effective_date).and_return effective_on
        allow(family).to receive(:is_under_special_enrollment_period?).and_return(false)
        expect(HbxEnrollment.calculate_effective_on_from(market_kind:'individual', qle:false, family: family, employee_role: nil, benefit_group: nil, benefit_sponsorship: benefit_sponsorship)).to eq effective_on
      end
    end
  end

  context "ivl user switching plan from one carrier to other carrier previous hbx_enrollment aasm_sate should be cancel/terminate in DB." do
    let(:person1) { FactoryGirl.create(:person, :with_consumer_role) }
    let(:family1) {FactoryGirl.create(:family, :with_primary_family_member, :person => person1)}
    let(:household) {FactoryGirl.create(:household, family: family1)}
    let(:date){ TimeKeeper.date_of_record }
    let!(:carrier_profile1) {FactoryGirl.build(:carrier_profile)}
    let!(:carrier_profile2) {FactoryGirl.create(:carrier_profile, organization: organization)}
    let!(:organization) { FactoryGirl.create(:organization, legal_name: "CareFirst", dba: "care")}
    let(:plan1){ Plan.new(active_year: date.year, market: "individual", carrier_profile: carrier_profile1) }
    let(:plan2){ Plan.new(active_year: date.year, market: "individual", carrier_profile: carrier_profile2) }

    let(:hbx_enrollment1){ HbxEnrollment.new(kind: "individual", plan: plan1, household: family1.latest_household, enrollment_kind: "open_enrollment", aasm_state: 'coverage_selected', consumer_role: person1.consumer_role, enrollment_signature: true) }
    let(:hbx_enrollment2){ HbxEnrollment.new(kind: "individual", plan: plan2, household: family1.latest_household, enrollment_kind: "open_enrollment", aasm_state: 'shopping', consumer_role: person1.consumer_role, enrollment_signature: true, effective_on: date) }

    before do
      TimeKeeper.set_date_of_record_unprotected!(Date.today + 20.days) if TimeKeeper.date_of_record.month == 1 || TimeKeeper.date_of_record.month == 12
    end

    after do
      TimeKeeper.set_date_of_record_unprotected!(Date.today) if TimeKeeper.date_of_record.month == 1 || TimeKeeper.date_of_record.month == 12
    end

    it "should cancel hbx enrollemnt plan1 from carrier1 when choosing plan2 from carrier2" do
      hbx_enrollment1.effective_on = date + 1.day
      hbx_enrollment2.effective_on = date
      # This gets processed on 31st Dec
      if hbx_enrollment1.effective_on.year != hbx_enrollment2.effective_on.year
        hbx_enrollment1.effective_on = date + 2.day
        hbx_enrollment2.effective_on = date + 1.day
      end
      hbx_enrollment2.select_coverage!
      hbx_enrollment1_from_db = HbxEnrollment.by_hbx_id(hbx_enrollment1.hbx_id).first
      expect(hbx_enrollment1_from_db.coverage_canceled?).to be_truthy
      expect(hbx_enrollment2.coverage_selected?).to be_truthy
    end

    it "should not cancel hbx enrollemnt of previous plan year enrollment" do
      hbx_enrollment1.effective_on = date + 1.year
      hbx_enrollment2.effective_on = date
      hbx_enrollment2.select_coverage!
      expect(hbx_enrollment1.coverage_canceled?).to be_falsy
      expect(hbx_enrollment2.coverage_selected?).to be_truthy
    end

    it "should terminate hbx enrollemnt plan1 from carrier1 when choosing hbx enrollemnt plan2 from carrier2" do
      hbx_enrollment1.effective_on = date - 10.days
      hbx_enrollment2.select_coverage!
      hbx_enrollment1_from_db = HbxEnrollment.by_hbx_id(hbx_enrollment1.hbx_id).first
      expect(hbx_enrollment1_from_db.coverage_terminated?).to be_truthy
      expect(hbx_enrollment2.coverage_selected?).to be_truthy
      expect(hbx_enrollment1_from_db.terminated_on).to eq hbx_enrollment2.effective_on - 1.day
    end

    it "terminates previous enrollments if both effective on in the future" do
      hbx_enrollment1.effective_on = date + 10.days
      hbx_enrollment2.effective_on = date + 20.days
      hbx_enrollment2.select_coverage!
      expect(hbx_enrollment1.coverage_terminated?).to be_truthy
      expect(hbx_enrollment2.coverage_selected?).to be_truthy
      expect(hbx_enrollment1.terminated_on).to eq hbx_enrollment2.effective_on - 1.day
    end

  end

  context "can_terminate_coverage?" do
    let(:hbx_enrollment) {HbxEnrollment.new(
                            kind: 'employer_sponsored',
                            aasm_state: 'coverage_selected',
                            effective_on: TimeKeeper.date_of_record - 10.days
    )}
    it "should return false when may not terminate_coverage" do
      hbx_enrollment.aasm_state = 'inactive'
      expect(hbx_enrollment.can_terminate_coverage?).to eq false
    end

    context "when may_terminate_coverage is true" do
      before :each do
        hbx_enrollment.aasm_state = 'coverage_selected'
      end

      it "should return true" do
        hbx_enrollment.effective_on = TimeKeeper.date_of_record - 10.days
        expect(hbx_enrollment.can_terminate_coverage?).to eq true
      end

      it "should return false" do
        hbx_enrollment.effective_on = TimeKeeper.date_of_record + 10.days
        expect(hbx_enrollment.can_terminate_coverage?).to eq false
      end
    end
  end

  context "cancel_coverage!", dbclean: :after_each do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: "inactive")}

    it "should cancel the enrollment" do
      hbx_enrollment.cancel_coverage!
      expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
    end

    it "should not populate the terminated on" do
      hbx_enrollment.cancel_coverage!
      expect(hbx_enrollment.terminated_on).to eq nil
    end
  end

   context "cancel_for_non_payment!", dbclean: :after_each do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: "inactive")}

    it "should cancel the enrollment" do
      hbx_enrollment.cancel_for_non_payment!
      expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
    end

    it "should not populate the terminated on" do
      hbx_enrollment.cancel_for_non_payment!
      expect(hbx_enrollment.terminated_on).to eq nil
    end
  end


   context "terminate_for_non_payment!", dbclean: :after_each do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
    let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, aasm_state: "coverage_selected")}

    it "should terminate enrollment" do
      hbx_enrollment.terminate_for_non_payment!
      expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
    end

    it "should  populate terminate on" do
      hbx_enrollment.terminate_for_non_payment!
      expect(hbx_enrollment.terminated_on).to eq hbx_enrollment.terminated_on
    end
  end


end

describe HbxEnrollment, dbclean: :after_each do

  let(:employer_profile)          { FactoryGirl.create(:employer_profile) }

  let(:calendar_year) { TimeKeeper.date_of_record.year }

  let(:middle_of_prev_year) { Date.new(calendar_year - 1, 6, 10) }
  let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', created_at: middle_of_prev_year, updated_at: middle_of_prev_year, hired_on: middle_of_prev_year) }
  let(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }

  let(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:plan_year_start_on) { Date.new(calendar_year, 1, 1) }
  let(:plan_year_end_on) { Date.new(calendar_year, 12, 31) }
  let(:open_enrollment_start_on) { Date.new(calendar_year - 1, 12, 1) }
  let(:open_enrollment_end_on) { Date.new(calendar_year - 1, 12, 10) }
  let(:effective_date)         { plan_year_start_on }


  let!(:plan_year)                               { py = FactoryGirl.create(:plan_year,
                                                                           start_on: plan_year_start_on,
                                                                           end_on: plan_year_end_on,
                                                                           open_enrollment_start_on: open_enrollment_start_on,
                                                                           open_enrollment_end_on: open_enrollment_end_on,
                                                                           employer_profile: employer_profile
                                                                           )

                                                   blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
                                                   white = FactoryGirl.build(:benefit_group, title: "white collar", plan_year: py)
                                                   py.benefit_groups = [blue, white]
                                                   py.save
                                                   py.update_attributes({:aasm_state => 'published'})
                                                   py
                                                   }


  let(:hired_on) { middle_of_prev_year }
  let(:created_at) { middle_of_prev_year }
  let(:census_employee) { FactoryGirl.create(:census_employee_with_active_assignment, employer_profile: employer_profile, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', created_at: created_at, updated_at: created_at, hired_on: hired_on, benefit_group: plan_year.benefit_groups.first) }

  let(:employee_role) {
      FactoryGirl.create(:employee_role, employer_profile: employer_profile, hired_on: census_employee.hired_on, census_employee_id: census_employee.id)
    }

  let(:shop_enrollment)   { FactoryGirl.build(:hbx_enrollment,
                                              household: shop_family.latest_household,
                                              coverage_kind: "health",
                                              effective_on: effective_date,
                                              enrollment_kind: "open_enrollment",
                                              kind: "employer_sponsored",
                                              submitted_at: effective_date - 10.days,
                                              benefit_group_id: plan_year.benefit_groups.first.id,
                                              employee_role_id: employee_role.id,
                                              benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id
                                              )}


  before do
    TimeKeeper.set_date_of_record_unprotected!(plan_year_start_on + 45.days)

    allow(employee_role).to receive(:benefit_group).and_return(plan_year.benefit_groups.first)
    # allow(shop_enrollment).to receive(:employee_role).and_return(employee_role)
    allow(shop_enrollment).to receive(:plan_year_check).with(employee_role).and_return false
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  context ".effective_date_for_enrollment" do
    context 'when new hire' do
      let(:hired_on) { TimeKeeper.date_of_record.beginning_of_month }
      let(:created_at) { TimeKeeper.date_of_record }

      it 'should return new hire effective date' do
        expect(employee_role.can_enroll_as_new_hire?).to be_truthy
        expect(HbxEnrollment.effective_date_for_enrollment(employee_role, shop_enrollment, false)).to eq census_employee.hired_on
      end
    end

    context 'when QLE' do
      let(:qle_date) { effective_date + 15.days }
      let(:qualifying_life_event_kind) { FactoryGirl.create(:qualifying_life_event_kind)}

      let(:special_enrollment_period) {
        special_enrollment = shop_family.special_enrollment_periods.build({
                                                                            qle_on: qle_date,
                                                                            effective_on_kind: "first_of_month",
        })
        special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
        special_enrollment.save!
        special_enrollment
      }

      before do
        allow(shop_family).to receive(:earliest_effective_shop_sep).and_return(special_enrollment_period)
      end

      it 'should return qle effective date' do
        expect(HbxEnrollment.effective_date_for_enrollment(employee_role, shop_enrollment, true)).to eq special_enrollment_period.effective_on
      end
    end

    context 'when under open enrollment' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(open_enrollment_start_on)
      end

      it 'should return open enrollment effective date' do
        expect(HbxEnrollment.effective_date_for_enrollment(employee_role, shop_enrollment, false)).to eq plan_year_start_on
      end
    end

    context 'when plan year not present' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(open_enrollment_start_on - 1.day)
        plan_year.update_attributes(:aasm_state => 'draft')
      end

      it 'should raise error' do
        expect { HbxEnrollment.effective_date_for_enrollment(employee_role, shop_enrollment, false) }.to raise_error(RuntimeError)
      end
    end

    context 'when plan year not under open enrollment' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(open_enrollment_start_on - 1.day)
      end

      it 'should raise error' do
        expect { HbxEnrollment.effective_date_for_enrollment(employee_role, shop_enrollment, false) }.to raise_error(RuntimeError)
      end
    end
  end

  context ".employee_current_benefit_group" do
    context 'when under open enrollment' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(open_enrollment_start_on)
      end

      it "should return benefit group and assignment" do
        expect(HbxEnrollment.employee_current_benefit_group(employee_role, shop_enrollment, false)).to eq [plan_year.benefit_groups.first, census_employee.active_benefit_group_assignment]
      end
    end
  end
end


describe HbxEnrollment, dbclean: :after_each do

  context ".can_select_coverage?" do
    let(:employer_profile)          { FactoryGirl.create(:employer_profile) }

    let(:calendar_year) { TimeKeeper.date_of_record.year }

    let(:middle_of_prev_year) { Date.new(calendar_year - 1, 6, 10) }
    let(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }

    let(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:plan_year_start_on) { Date.new(calendar_year, 1, 1) }
    let(:plan_year_end_on) { Date.new(calendar_year, 12, 31) }
    let(:open_enrollment_start_on) { Date.new(calendar_year - 1, 12, 1) }
    let(:open_enrollment_end_on) { Date.new(calendar_year - 1, 12, 10) }
    let(:effective_date)         { plan_year_start_on }


    let!(:plan_year)                               { py = FactoryGirl.create(:plan_year,
                                                                             start_on: plan_year_start_on,
                                                                             end_on: plan_year_end_on,
                                                                             open_enrollment_start_on: open_enrollment_start_on,
                                                                             open_enrollment_end_on: open_enrollment_end_on,
                                                                             employer_profile: employer_profile
                                                                             )

                                                     blue = FactoryGirl.build(:benefit_group, title: "blue collar", plan_year: py)
                                                     white = FactoryGirl.build(:benefit_group, title: "white collar", plan_year: py)
                                                     py.benefit_groups = [blue, white]
                                                     py.save
                                                     py.update_attributes({:aasm_state => 'published'})
                                                     py
                                                     }

    let(:hired_on) { middle_of_prev_year }
    let(:created_at) { middle_of_prev_year }
    let(:updated_at) { middle_of_prev_year }

    let(:census_employee) { FactoryGirl.create(:census_employee_with_active_assignment, employer_profile: employer_profile, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', created_at: created_at, updated_at: updated_at, hired_on: hired_on, benefit_group: plan_year.benefit_groups.first) }

    let(:employee_role) {
      FactoryGirl.create(:employee_role, employer_profile: employer_profile, hired_on: census_employee.hired_on, census_employee_id: census_employee.id)
    }

    let(:shop_enrollment)   { FactoryGirl.create(:hbx_enrollment,
                                                 household: shop_family.latest_household,
                                                 coverage_kind: "health",
                                                 effective_on: effective_date,
                                                 enrollment_kind: "open_enrollment",
                                                 kind: "employer_sponsored",
                                                 submitted_at: effective_date - 10.days,
                                                 benefit_group_id: plan_year.benefit_groups.first.id,
                                                 employee_role_id: employee_role.id,
                                                 benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id
                                                 )
                              }

    before do
      allow(employee_role).to receive(:benefit_group).and_return(plan_year.benefit_groups.first)
      allow(shop_enrollment).to receive(:plan_year_check).with(employee_role).and_return false
    end

    context 'under open enrollment' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(open_enrollment_start_on)
      end

      it "should allow" do
        expect(shop_enrollment.can_select_coverage?).to be_truthy
      end
    end

    context 'outside open enrollment' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(open_enrollment_end_on + 5.days)
      end

      it "should not allow" do
        expect(shop_enrollment.can_select_coverage?).to be_falsey
      end
    end

    context 'when its a new hire' do
      let(:hired_on) { Date.new(calendar_year, 3, 1) }
      let(:created_at) { Date.new(calendar_year, 2, 1) }
      let(:updated_at) { Date.new(calendar_year, 2, 1) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(calendar_year, 3, 15))
      end

      it "should allow" do
        expect(shop_enrollment.can_select_coverage?).to be_truthy
      end
    end

    context 'when not a new hire' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(calendar_year, 3, 15))
      end

      it "should not allow" do
        expect(shop_enrollment.can_select_coverage?).to be_falsey
      end

      it "should get a error msg" do
        shop_enrollment.can_select_coverage?
        expect(shop_enrollment.errors.any?).to be_truthy
        expect(shop_enrollment.errors.full_messages.to_s).to match /You can not keep an existing plan which belongs to previous plan year/
      end
    end

    context 'when roster create present' do
      let(:hired_on) { middle_of_prev_year }
      let(:created_at) { Date.new(calendar_year, 5, 10) }
      let(:updated_at) { Date.new(calendar_year, 5, 10) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(calendar_year, 5, 15))
      end

      it "should allow" do
        expect(shop_enrollment.can_select_coverage?).to be_truthy
      end
    end

    context 'when roster update not present' do
      let(:hired_on) { middle_of_prev_year }
      let(:created_at) { middle_of_prev_year }
      let(:updated_at) { Date.new(calendar_year, 5, 10) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(calendar_year, 5, 9))
      end

      it "should not allow" do
        expect(shop_enrollment.can_select_coverage?).to be_falsey
      end

      it "should get a error msg" do
        shop_enrollment.can_select_coverage?
        expect(shop_enrollment.errors.any?).to be_truthy
        expect(shop_enrollment.errors.full_messages.to_s).to match /You can not keep an existing plan which belongs to previous plan year/
      end
    end

    context 'with QLE' do

      let(:qle_date) { effective_date + 15.days }
      let(:qualifying_life_event_kind) { FactoryGirl.create(:qualifying_life_event_kind)}
      let(:user) { instance_double("User", :primary_family => test_family, :person => person) }
      let(:qle) { FactoryGirl.create(:qualifying_life_event_kind) }
      let(:test_family) { FactoryGirl.build(:family, :with_primary_family_member) }
      let(:person) { shop_family.primary_family_member.person }
      let(:published_plan_year)  { FactoryGirl.build(:plan_year, aasm_state: :published)}
      let(:employer_profile) { FactoryGirl.create(:employer_profile) }
      let(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person, census_employee: census_employee ) }
      let(:employee_role_id) { employee_role.id }
      let(:new_census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: middle_of_prev_year, created_at: Date.new(calendar_year, 5, 10), updated_at: Date.new(calendar_year, 5, 10)) }


      let(:special_enrollment_period) {
        special_enrollment = shop_family.special_enrollment_periods.build({
                                                                            qle_on: qle_date,
                                                                            effective_on_kind: "first_of_month",
        })
        special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
        special_enrollment.save
        special_enrollment
      }

      let(:shop_enrollment)   { FactoryGirl.create(:hbx_enrollment,
                                                   household: shop_family.latest_household,
                                                   coverage_kind: "health",
                                                   effective_on: effective_date,
                                                   enrollment_kind: "special_enrollment",
                                                   kind: "employer_sponsored",
                                                   submitted_at: effective_date - 10.days,
                                                   benefit_group_id: plan_year.benefit_groups.first.id,
                                                   employee_role_id: employee_role.id,
                                                   benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                                   special_enrollment_period_id: special_enrollment_period.id
                                                   )
                                }

      before do
        allow(shop_enrollment).to receive(:plan_year_check).with(employee_role).and_return false
      end
      context 'under special enrollment period' do
        before do
          TimeKeeper.set_date_of_record_unprotected!( special_enrollment_period.end_on - 5.days )
        end

        it "should allow" do
          expect(shop_enrollment.can_select_coverage?).to be_truthy
        end
      end

      context 'outside special enrollment period' do
        before do
          TimeKeeper.set_date_of_record_unprotected!( special_enrollment_period.end_on + 5.days )
        end

        it "should not allow" do
          expect(shop_enrollment.can_select_coverage?).to be_falsey
        end
      end
    end
  end
end

context "Benefits are terminated" do
  let(:effective_on_date)         { TimeKeeper.date_of_record.beginning_of_month }
  let(:benefit_group)             { FactoryGirl.create(:benefit_group) }
  let!(:hbx_profile)               { FactoryGirl.create(:hbx_profile) }

  before do
    TimeKeeper.set_date_of_record_unprotected!(Date.new(effective_on_date.year, 6, 1))
  end

  context "Individual benefit" do
    let(:ivl_family)        { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:ivl_enrollment)    { FactoryGirl.create(:hbx_enrollment,
                                                 household: ivl_family.latest_household,
                                                 coverage_kind: "health",
                                                 effective_on: effective_on_date,
                                                 enrollment_kind: "open_enrollment",
                                                 kind: "individual",
                                                 submitted_at: effective_on_date - 10.days
                                                 )
                              }
    let(:ivl_termination_date)  { TimeKeeper.date_of_record}

    it "should be open enrollment" do
      expect(ivl_enrollment.is_open_enrollment?).to be_truthy
    end

    context "and coverage is terminated" do
      before do
        ivl_enrollment.terminate_benefit(TimeKeeper.date_of_record)
      end

      it "should have terminated date" do
        expect(ivl_enrollment.terminated_on).to eq ivl_termination_date
      end

      it "should be in terminated state" do
        expect(ivl_enrollment.aasm_state).to eq "coverage_terminated"
      end
    end
  end

  context "SHOP benefit" do
    let(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:census_employee)   { FactoryGirl.create(:census_employee)}
    let(:employee_role)     { FactoryGirl.create(:employee_role)}
    let(:shop_enrollment)   { FactoryGirl.create(:hbx_enrollment,
                                                 household: shop_family.latest_household,
                                                 coverage_kind: "health",
                                                 effective_on: effective_on_date,
                                                 enrollment_kind: "open_enrollment",
                                                 kind: "employer_sponsored",
                                                 submitted_at: effective_on_date - 10.days,
                                                 benefit_group_id: benefit_group.id,
                                                 employee_role_id: employee_role.id
                                                 )
                              }

    let(:shop_termination_date)  { TimeKeeper.date_of_record.end_of_month }

    before do
      employee_role.update_attributes(census_employee_id: census_employee.id)
    end

    it "should be SHOP enrollment kind" do
      expect(shop_enrollment.is_shop?).to be_truthy
    end

    it "should be SHOP enrollment kind when employer_sponsored_cobra" do
      shop_enrollment.kind = 'employer_sponsored_cobra'
      expect(shop_enrollment.kind).to eq 'employer_sponsored_cobra'
      expect(shop_enrollment.is_shop?).to be_truthy
    end

    context "and coverage is terminated" do
      before do
        shop_enrollment.terminate_benefit(TimeKeeper.date_of_record)
      end

      it "should have terminated date" do
        expect(shop_enrollment.terminated_on).to eq shop_termination_date
      end

      it "should be in terminated state" do
        expect(shop_enrollment.aasm_state).to eq "coverage_terminated"
      end
    end
  end
end





# describe HbxEnrollment, "#save", type: :model do
#
#   context "SHOP market validations" do
#     context "plan coverage is valid" do
#       context "selected plan is not for SHOP market" do
#         it "should return an error" do
#         end
#       end
#
#       context "selected plan is not offered by employer" do
#         it "should return an error" do
#         end
#       end
#
#       context "selected plan is not active on effective date" do
#         it "should return an error" do
#         end
#       end
#     end
#
#     context "effective date is valid" do
#       context "Special Enrollment Period" do
#       end
#
#       context "open enrollment" do
#       end
#     end
#
#     context "premium is valid" do
#       it "should include a valid total premium amount" do
#       end
#
#       it "should include a valid employer_profile contribution amount" do
#       end
#
#       it "should include a valid employee_role contribution amount" do
#       end
#     end
#
#     context "correct EDI event is created" do
#     end
#
#     context "correct employee_role notice is created" do
#     end
#
#   end
#
#   context "IVL market validations" do
#   end
#
# end
#
# describe HbxEnrollment, ".new", type: :model do
#
#   context "employer_role is enrolling in SHOP market" do
#     context "employer_profile is under open enrollment period" do
#         it "should instantiate object" do
#         end
#     end
#
#     context "outside employer open enrollment" do
#       context "employee_role is under special enrollment period" do
#         it "should instantiate object" do
#         end
#
#       end
#
#       context "employee_role isn't under special enrollment period" do
#         it "should return an error" do
#         end
#       end
#     end
#   end
#
#   context "consumer_role is enrolling in individual market" do
#   end
# end
#
#
# ## Retroactive enrollments??
#
#
# describe HbxEnrollment, "SHOP open enrollment period", type: :model do
#  context "person is enrolling for SHOP coverage" do
#     context "employer is under open enrollment period" do
#
#       context "and employee_role is under special enrollment period" do
#
#         context "and sep coverage effective date preceeds open enrollment effective date" do
#
#           context "and selected plan is for next plan year" do
#             context "and no active coverage exists for employee_role" do
#               context "and employee_role hasn't confirmed 'gap' coverage start date" do
#                 it "should record employee_role confirmation (user & timestamp)" do
#                 end
#               end
#
#               context "and employee_role has confirmed 'gap' coverage start date" do
#                 it "should process enrollment" do
#                 end
#               end
#             end
#           end
#
#           context "and selected plan is for current plan year" do
#             it "should process enrollment" do
#             end
#           end
#
#         end
#
#         context "and sep coverage effective date is later than open enrollment effective date" do
#           context "and today's date is past open enrollment period" do
#             it "and should process enrollment" do
#             end
#           end
#         end
#
#       end
#     end
#   end
# end
#
# describe HbxEnrollment, "SHOP special enrollment period", type: :model do
#
#   context "and person is enrolling for SHOP coverage" do
#
#     context "and outside employer open enrollment" do
#       context "employee_role is under a special enrollment period" do
#       end
#
#       context "employee_role isn't under a special enrollment period" do
#         it "should return error" do
#         end
#       end
#     end
#   end
# end
#
#
# ## Coverage of same type
# describe HbxEnrollment, "employee_role has active coverage", type: :model do
#   context "enrollment is with same employer" do
#
#     context "and new effective date is later than effective date on active coverage" do
#       it "should replace existing enrollment and notify employee_role" do
#       end
#
#       it "should fire an EDI event: terminate coverage" do
#       end
#
#       it "should fire an EDI event: enroll coverage" do
#       end
#
#       it "should trigger notice to employee_role" do
#       end
#     end
#
#     context "and new effective date is later prior to effective date on active coverage"
#       it "should replace existing enrollment" do
#       end
#
#       it "should fire an EDI event: cancel coverage" do
#       end
#
#       it "should fire an EDI event: enroll coverage" do
#       end
#
#       it "should trigger notice to employee_role" do
#       end
#   end
#
#   context "and enrollment coverage is with different employer" do
#     context "and employee specifies enrollment termination with other employer" do
#       it "should send other employer termination request notice" do
#       end
#
#     end
#
#     ### otherwise process enrollment
#   end
#
#   context "active coverage is with person's consumer_role" do
#   end
# end
#
# describe HbxEnrollment, "consumer_role has active coverage", type: :model do
# end
#
# describe HbxEnrollment, "Enrollment renewal", type: :model do
#
#   context "person is enrolling for IVL coverage" do
#
#     context "HBX is under open enrollment period" do
#     end
#
#     context "outside HBX open enrollment" do
#       context "consumer_role is under a special enrollment period" do
#       end
#
#       context "consumer_role isn't under a special enrollment period" do
#       end
#     end
#   end
# end

describe HbxEnrollment, "given a set of broker accounts" do
  let(:submitted_at) { Time.mktime(2008, 12, 13, 12, 34, 00) }
  subject { HbxEnrollment.new(:submitted_at => submitted_at) }
  let(:broker_agency_account_1) { double(:start_on => start_on_1, :end_on => end_on_1) }
  let(:broker_agency_account_2) { double(:start_on => start_on_2, :end_on => end_on_2) }

  describe "with both accounts active before the purchase, and the second one unterminated" do
    let(:start_on_1) { submitted_at - 12.days }
    let(:start_on_2) { submitted_at - 5.days }
    let(:end_on_1) { nil }
    let(:end_on_2) { nil }

    it "should be able to select the applicable broker" do
      expect(subject.select_applicable_broker_account([broker_agency_account_1,broker_agency_account_2])).to eq broker_agency_account_2
    end
  end

  describe "with both accounts active before the purchase, and the later one terminated" do
    let(:start_on_1) { submitted_at - 12.days }
    let(:start_on_2) { submitted_at - 5.days }
    let(:end_on_1) { nil }
    let(:end_on_2) { submitted_at - 2.days }

    it "should have no applicable broker" do
      expect(subject.select_applicable_broker_account([broker_agency_account_1,broker_agency_account_2])).to eq nil
    end
  end

  describe "with one account active before the purchase, and the other active after" do
    let(:start_on_1) { submitted_at - 12.days }
    let(:start_on_2) { submitted_at + 5.days }
    let(:end_on_1) { nil }
    let(:end_on_2) { nil }

    it "should be able to select the applicable broker" do
      expect(subject.select_applicable_broker_account([broker_agency_account_1,broker_agency_account_2])).to eq broker_agency_account_1
    end
  end

  describe "with one account active before the purchase and terminated before the purchase, and the other active after" do
    let(:start_on_1) { submitted_at - 12.days }
    let(:start_on_2) { submitted_at + 5.days }
    let(:end_on_1) { submitted_at - 3.days }
    let(:end_on_2) { nil }

    it "should have no applicable broker" do
      expect(subject.select_applicable_broker_account([broker_agency_account_1,broker_agency_account_2])).to eq nil
    end
  end
end

describe HbxEnrollment, "given an enrollment kind of 'special_enrollment'" do
  subject { HbxEnrollment.new({:enrollment_kind => "special_enrollment"}) }

  it "should NOT be a shop new hire" do
    expect(subject.new_hire_enrollment_for_shop?).to eq false
  end

  describe "and given a special enrollment period, with a reason of 'birth'" do
    let(:qle_on) { Date.today }

    before :each do
      allow(subject).to receive(:special_enrollment_period).and_return(SpecialEnrollmentPeriod.new(
                                                                         :qualifying_life_event_kind => QualifyingLifeEventKind.new(:reason => "birth"),
                                                                         :qle_on => qle_on
      ))
    end

    it "should have the eligibility event date of the qle_on" do
      expect(subject.eligibility_event_date).to eq qle_on
    end

    it "should have eligibility_event_kind of 'birth'" do
      expect(subject.eligibility_event_kind).to eq "birth"
    end
  end

end

describe HbxEnrollment, "given an enrollment kind of 'open_enrollment'" do
  subject { HbxEnrollment.new({:enrollment_kind => "open_enrollment"}) }

  it "should not have an eligibility event date" do
    expect(subject.eligibility_event_has_date?).to eq false
  end

  describe "in the IVL market" do
    before :each do
      subject.kind = "unassisted_qhp"
    end

    it "should not have an eligibility event date" do
      expect(subject.eligibility_event_has_date?).to eq false
    end

    it "should NOT be a shop new hire" do
      expect(subject.new_hire_enrollment_for_shop?).to eq false
    end

    it "should have eligibility_event_kind of 'open_enrollment'" do
      expect(subject.eligibility_event_kind).to eq "open_enrollment"
    end
  end

  describe "in the SHOP market, purchased outside of open enrollment" do
    let(:reference_date) { Date.today }
    let(:open_enrollment_start) { reference_date - 15.days }
    let(:open_enrollment_end) { reference_date - 5.days }
    let(:purchase_time) { Time.now - 20.days }
    let(:hired_on) { reference_date - 21.days }

    before :each do
      subject.kind = "employer_sponsored"
      subject.submitted_at = purchase_time
      subject.benefit_group_assignment = BenefitGroupAssignment.new({
                                                                      :census_employee => CensusEmployee.new({
                                                                                                               :hired_on => hired_on
                                                                      })
      })

      benefit_group =  BenefitGroup.new({
       :plan_year => PlanYear.new({
        :open_enrollment_start_on => open_enrollment_start,
        :open_enrollment_end_on => open_enrollment_end
        })
      })

      subject.benefit_group = benefit_group
      allow(subject).to receive(:benefit_group).and_return(benefit_group)
    end
    it "should have an eligibility event date" do
      expect(subject.eligibility_event_has_date?).to eq true
    end

    it "should be a shop new hire" do
      expect(subject.new_hire_enrollment_for_shop?).to eq true
    end

    it "should have eligibility_event_kind of 'new_hire'" do
      expect(subject.eligibility_event_kind).to eq "new_hire"
    end

    it "should have the eligibility event date of hired_on" do
      expect(subject.eligibility_event_date).to eq hired_on
    end
  end

  describe "in the SHOP market, purchased during open enrollment" do
    let(:reference_date) { Time.now }
    let(:coverage_start) { (reference_date + 15.days).to_date }
    let(:open_enrollment_start) { (reference_date - 15.days).to_date }
    let(:open_enrollment_end) { (reference_date - 5.days).to_date }
    let(:purchase_time) { (reference_date - 5.days).midnight + 200.minutes }
    let(:hired_on) { (reference_date - 21.days).to_date }

    before :each do
      subject.kind = "employer_sponsored"
      subject.submitted_at = purchase_time
      subject.benefit_group_assignment = BenefitGroupAssignment.new({
                                                                      :census_employee => CensusEmployee.new({
                                                                                                               :hired_on => hired_on
                                                                      })
      })

      benefit_group = BenefitGroup.new({
       :plan_year => PlanYear.new({
        :open_enrollment_start_on => open_enrollment_start,
        :open_enrollment_end_on => open_enrollment_end,
        :start_on => coverage_start
        })
      })

      subject.benefit_group = benefit_group
      allow(subject).to receive(:benefit_group).and_return(benefit_group)
    end

    describe "when coverage start is the same as the plan year" do
      before(:each) do
        subject.effective_on = coverage_start
      end

      it "should NOT have an eligibility event date" do
        expect(subject.eligibility_event_has_date?).to eq false
      end

      it "should NOT be a shop new hire" do
        expect(subject.new_hire_enrollment_for_shop?).to eq false
      end

      it "should have eligibility_event_kind of 'open_enrollment'" do
        expect(subject.eligibility_event_kind).to eq "open_enrollment"
      end
    end

    describe "when coverage start is the different from the plan year" do
      before(:each) do
        subject.effective_on = coverage_start + 12.days
      end

      it "should have an eligibility event date" do
        expect(subject.eligibility_event_has_date?).to eq true
      end

      it "should be a shop new hire" do
        expect(subject.new_hire_enrollment_for_shop?).to eq true
      end

      it "should have eligibility_event_kind of 'new_hire'" do
        expect(subject.eligibility_event_kind).to eq "new_hire"
      end

      it "should have the eligibility event date of hired_on" do
        expect(subject.eligibility_event_date).to eq hired_on
      end
    end
  end
end

describe HbxEnrollment, 'dental shop calculation related', type: :model, dbclean: :after_all do
  include_context "BradyWorkAfterAll"

  before :all do
    create_brady_census_families
  end

  context "shop_market without dental health minimal requirement calculation " do
    attr_reader :enrollment, :household, :coverage_household
    before :all do
      @household = mikes_family.households.first
      @coverage_household = household.coverage_households.first
      @enrollment = household.create_hbx_enrollment_from(
        employee_role: mikes_employee_role,
        coverage_household: coverage_household,
        benefit_group: mikes_benefit_group,
        benefit_group_assignment: @mikes_benefit_group_assignments
      )
    end

    it "should return the hbx_enrollments with the benefit group assignment" do
      enrollment.aasm_state = 'coverage_selected'
      enrollment.save
      rs = HbxEnrollment.find_enrollments_by_benefit_group_assignment(enrollment.benefit_group_assignment)
      expect(rs).to include enrollment
    end

    it "should be empty while the enrollment is not health and status is not showing" do
      enrollment.aasm_state = 'shopping'
      enrollment.save
      rs = HbxEnrollment.find_enrollments_by_benefit_group_assignment(enrollment.benefit_group_assignment)
      expect(rs).to be_empty
    end

    it "should not return the hbx_enrollments while the enrollment is dental and status is not showing" do
      enrollment.update_attributes(coverage_kind: 'dental', aasm_state: 'coverage_selected')
      rs = HbxEnrollment.find_enrollments_by_benefit_group_assignment(enrollment.benefit_group_assignment)
      expect(rs).to include enrollment
    end
  end

  context "update_coverage_kind_by_plan" do
    let(:plan) { FactoryGirl.create(:plan, coverage_kind: 'health') }
    attr_reader :enrollment, :household, :coverage_household
    before :all do
      @household = mikes_family.households.first
      @coverage_household = household.coverage_households.first
      @enrollment = household.create_hbx_enrollment_from(
        employee_role: mikes_employee_role,
        coverage_household: coverage_household,
        benefit_group: mikes_benefit_group,
        benefit_group_assignment: @mikes_benefit_group_assignments
      )
    end

    it "should update coverage_kind by plan" do
      enrollment.plan = plan
      enrollment.coverage_kind = 'dental'
      enrollment.update_coverage_kind_by_plan
      expect(enrollment.coverage_kind).to eq enrollment.plan.coverage_kind
    end
  end
end

context "A cancelled external enrollment", :dbclean => :after_each do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:enrollment) do
    FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       kind: "employer_sponsored",
                       submitted_at: TimeKeeper.datetime_of_record - 3.day,
                       created_at: TimeKeeper.datetime_of_record - 3.day
                       )
  end

  before do
    enrollment.aasm_state = "coverage_canceled"
    enrollment.terminated_on = enrollment.effective_on
    enrollment.external_enrollment = true
    enrollment.hbx_enrollment_members.each do |em|
      em.coverage_end_on = em.coverage_start_on
    end
    enrollment.save!
  end

  it "should not be visible to the family" do
    expect(family.enrollments_for_display.to_a).to eq([])
  end

  it "should not be visible to the family" do
    enrollment.aasm_state = "coverage_terminated"
    enrollment.external_enrollment = true
    enrollment.save!
    expect(family.enrollments_for_display.to_a).to eq([])
  end

  it "should not be visible to the family" do
    enrollment.aasm_state = "coverage_selected"
    enrollment.external_enrollment = true
    enrollment.save!
    expect(family.enrollments_for_display.to_a).to eq([])
  end

  it "should not be visible to the family" do
    enrollment.aasm_state = "coverage_canceled"
    enrollment.external_enrollment = false
    enrollment.save!
    expect(family.enrollments_for_display.to_a).to eq([])
  end

  it "should not be visible to the family" do
    enrollment.aasm_state = "coverage_canceled"
    enrollment.external_enrollment = true
    enrollment.save!
    expect(family.enrollments_for_display.to_a).to eq([])
  end

  it "should not be visible to the family" do
    enrollment.aasm_state = "coverage_selected"
    enrollment.external_enrollment = false
    enrollment.save!
    expect(family.enrollments_for_display.to_a).not_to eq([])
  end

  it "should not be visible to the family" do
    enrollment.aasm_state = "coverage_terminated"
    enrollment.external_enrollment = false
    enrollment.save!
    expect(family.enrollments_for_display.to_a).not_to eq([])
  end
end

context "for cobra", :dbclean => :after_each do
  let(:enrollment) { HbxEnrollment.new(kind: 'employer_sponsored') }
  let(:cobra_enrollment) { HbxEnrollment.new(kind: 'employer_sponsored_cobra') }

  context "is_cobra_status?" do
    it "should return false" do
      expect(enrollment.is_cobra_status?).to be_falsey
    end

    it "should return true" do
      enrollment.kind = 'employer_sponsored_cobra'
      expect(enrollment.is_cobra_status?).to be_truthy
    end
  end

  context "cobra_future_active?" do
    it "should return false when not cobra" do
      expect(enrollment.cobra_future_active?).to be_falsey
    end

    context "when cobra" do
      it "should return false" do
        allow(cobra_enrollment).to receive(:future_active?).and_return false
        expect(cobra_enrollment.cobra_future_active?).to be_falsey
      end

      it "should return true" do
        allow(cobra_enrollment).to receive(:future_active?).and_return true
        expect(cobra_enrollment.cobra_future_active?).to be_truthy
      end
    end
  end

  context "future_enrollment_termination_date" do
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee) }
    let(:coverage_termination_date) { TimeKeeper.date_of_record + 1.months }

    it "should return blank if not coverage_termination_pending" do
      expect(enrollment.future_enrollment_termination_date).to eq ""
    end

    it "should return coverage_termination_date by census_employee" do
      census_employee.coverage_terminated_on = coverage_termination_date
      employee_role.census_employee = census_employee
      enrollment.employee_role = employee_role
      enrollment.aasm_state = "coverage_termination_pending"
      expect(enrollment.future_enrollment_termination_date).to eq coverage_termination_date
    end
  end

  it "can_select_coverage?" do
    enrollment.kind = 'employer_sponsored_cobra'
    expect(enrollment.can_select_coverage?).to be_truthy
  end

  context "benefit_package_name" do
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:benefit_package) { BenefitPackage.new(title: 'benefit package title') }
    it "for shop" do
      enrollment.kind = 'employer_sponsored'
      enrollment.benefit_group = benefit_group
      expect(enrollment.benefit_package_name).to eq benefit_group.title
    end
  end
end

context '.process_verification_reminders' do

  context "when family exists with pending outstanding verifications" do

    let(:consumer_role) { FactoryGirl.create(:consumer_role) }
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, e_case_id: rand(10000), person: consumer_role.person) }
    let(:plan) { FactoryGirl.create(:plan) }

    let(:hbx_enrollment) {
      enrollment = family.active_household.new_hbx_enrollment_from(
        consumer_role: consumer_role,
        coverage_household: family.active_household.coverage_households.first,
        benefit_package: benefit_package,
        qle: true
      )
      enrollment.plan_id = plan.id
      enrollment.aasm_state = 'coverage_selected'
      enrollment
    }

    before do
      allow(family).to receive(:is_under_ivl_open_enrollment?).and_return(true)
      hbx_enrollment.save
      consumer_role.lawful_presence_determination.update_attributes(:aasm_state => 'verification_outstanding')
      consumer_role.update_attributes(:aasm_state => 'verification_outstanding')
    end

    context 'when first verification due date reached' do
      before do
        hbx_enrollment.update_attributes(special_verification_period: 85.days.from_now)
      end

      it 'should trigger first reminder event' do
        HbxEnrollment.process_verification_reminders(TimeKeeper.date_of_record)
        consumer_role.reload
        expect(consumer_role.workflow_state_transitions.present?).to be_truthy
      end
    end

    context 'when second verification due date reached' do
      before do
        hbx_enrollment.update_attributes(special_verification_period: 70.days.from_now)
      end

      it 'should trigger second reminder event' do
        HbxEnrollment.process_verification_reminders(TimeKeeper.date_of_record)
        consumer_role.reload
        expect(consumer_role.workflow_state_transitions.present?).to be_truthy
      end
    end

    context 'when third verification due date reached' do
      before do
        hbx_enrollment.update_attributes(special_verification_period: 45.days.from_now)
      end

      it 'should trigger third reminder event' do
        HbxEnrollment.process_verification_reminders(TimeKeeper.date_of_record)
        consumer_role.reload
        expect(consumer_role.workflow_state_transitions.present?).to be_truthy
      end
    end

    context 'when fourth verification due date reached' do
      before do
        hbx_enrollment.update_attributes(special_verification_period: 30.days.from_now)
      end

      it 'should trigger fourth reminder event' do
        HbxEnrollment.process_verification_reminders(TimeKeeper.date_of_record)
        consumer_role.reload
        expect(consumer_role.workflow_state_transitions.present?).to be_truthy
      end
    end
  end
end

# describe HbxEnrollment, 'Terminate/Cancel current enrollment when new coverage selected', type: :model, dbclean: :after_all do
describe HbxEnrollment, 'Updating Existing Coverage', type: :model, dbclean: :after_all do

  let!(:employer_profile) {
    org = FactoryGirl.create :organization, legal_name: "Corp 1"
    FactoryGirl.create :employer_profile, organization: org
  }

  let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month - 1.year }
  let(:end_on) { start_on + 1.year - 1.day }
  let(:open_enrollment_start_on) { start_on - 2.months }
  let(:open_enrollment_end_on) { open_enrollment_start_on.next_month + 9.days }

  let!(:renewal_plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.year + 1, hios_id: "11111111122302-01", csr_variant_id: "01")
  }

  let!(:plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: renewal_plan.id)
  }

  let!(:current_plan_year) {
    FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on, end_on: end_on, open_enrollment_start_on: open_enrollment_start_on, open_enrollment_end_on: open_enrollment_end_on, fte_count: 2, aasm_state: :active
  }

  let!(:current_benefit_group){
    FactoryGirl.create :benefit_group, plan_year: current_plan_year, reference_plan_id: plan.id
  }

  let!(:census_employees){
    FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
    employee = FactoryGirl.create :census_employee, employer_profile: employer_profile
    employee.add_benefit_group_assignment current_benefit_group, current_benefit_group.start_on
  }

  let(:ce) { employer_profile.census_employees.non_business_owner.first }

  let!(:family) {
    person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
  }

  let(:person) { family.primary_applicant.person }

  let!(:enrollment) {
    FactoryGirl.create(:hbx_enrollment,
                       household: family.active_household,
                       coverage_kind: "health",
                       effective_on: current_benefit_group.start_on,
                       enrollment_kind: "open_enrollment",
                       kind: "employer_sponsored",
                       submitted_at: current_benefit_group.start_on - 20.days,
                       benefit_group_id: current_benefit_group.id,
                       employee_role_id: person.active_employee_roles.first.id,
                       benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
                       plan_id: plan.id
                       )
  }

  context 'When family has active coverage and makes changes for their coverage' do

    let(:new_enrollment) {
      FactoryGirl.create(:hbx_enrollment,
                         household: family.active_household,
                         coverage_kind: "health",
                         effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                         enrollment_kind: "open_enrollment",
                         kind: "employer_sponsored",
                         submitted_at: TimeKeeper.date_of_record,
                         benefit_group_id: current_benefit_group.id,
                         employee_role_id: person.active_employee_roles.first.id,
                         benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
                         plan_id: plan.id,
                         aasm_state: 'shopping'
                         )
    }
    before do
      allow(new_enrollment).to receive(:plan_year_check).with(ce.employee_role).and_return false
    end

    it 'should terminate existing coverage' do
      expect(enrollment.coverage_selected?).to be_truthy
      expect(enrollment.terminated_on).to be_nil
      new_enrollment.select_coverage!
      expect(enrollment.coverage_terminated?).to be_truthy
      expect(enrollment.terminated_on).to eq(new_enrollment.effective_on - 1.day)
    end
  end

  context 'When family passively renewed' do

    let!(:renewing_plan_year) {
      FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, end_on: end_on + 1.year, open_enrollment_start_on: open_enrollment_start_on + 1.year, open_enrollment_end_on: open_enrollment_end_on + 1.year + 3.days, fte_count: 2, aasm_state: :renewing_enrolling
    }

    let!(:renewal_benefit_group){ FactoryGirl.create :benefit_group, plan_year: renewing_plan_year, reference_plan_id: renewal_plan.id, elected_plan_ids: elected_plans }
    let!(:renewal_benefit_group_assignment) { employer_profile.census_employees.each{|ce| ce.add_renew_benefit_group_assignment [renewal_benefit_group]; ce.save!;} }

    let!(:generate_passive_renewal) {
      ce.update!(created_at: 2.months.ago)

      factory = Factories::FamilyEnrollmentRenewalFactory.new
      factory.family = family
      factory.census_employee = ce.reload
      factory.employer = employer_profile
      factory.renewing_plan_year = employer_profile.renewing_plan_year
      factory.renew
    }

    let!(:new_plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: start_on.year + 1, hios_id: "11111111122301-01", csr_variant_id: "01")
    }

    let(:elected_plans) { [renewal_plan.id] }

    context 'When Actively Renewed' do

      let(:new_enrollment) {
        FactoryGirl.create(:hbx_enrollment,
         household: family.active_household,
         coverage_kind: "health",
         effective_on: renewing_plan_year.start_on,
         enrollment_kind: "open_enrollment",
         kind: "employer_sponsored",
         submitted_at: TimeKeeper.date_of_record,
         benefit_group_id: renewal_benefit_group.id,
         employee_role_id: person.active_employee_roles.first.id,
         benefit_group_assignment_id: ce.renewal_benefit_group_assignment.id,
         plan_id: new_plan.id,
         aasm_state: 'shopping'
         )
      }


      context 'with same effective date as passive renewal' do
        it 'should cancel their passive renewal' do
          passive_renewal = family.enrollments.where(:aasm_state => 'auto_renewing').first
          expect(passive_renewal).not_to be_nil

          new_enrollment.select_coverage!
          passive_renewal.reload
          new_enrollment.reload

          expect(passive_renewal.coverage_canceled?).to be_truthy
          expect(new_enrollment.coverage_selected?).to be_truthy
        end
      end

      context 'with effective date later to the passive renewal' do

        before do
          new_enrollment.update_attributes(:effective_on => renewing_plan_year.start_on + 1.month)
          allow(new_enrollment).to receive(:plan_year_check).with(ce.employee_role).and_return false
        end

        it 'should terminate the passive renewal' do
          passive_renewal = family.enrollments.where(:aasm_state => 'auto_renewing').first
          expect(passive_renewal).not_to be_nil

          new_enrollment.select_coverage!
          passive_renewal.reload
          new_enrollment.reload

          expect(new_enrollment.coverage_selected?).to be_truthy
          expect(passive_renewal.coverage_terminated?).to be_truthy
          expect(passive_renewal.terminated_on).to eq(new_enrollment.effective_on - 1.day)
        end
      end
    end

    context '.update_renewal_coverage' do
      context 'when EE enters SEP and picks new plan' do

        let(:new_renewal_plan) {
          FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.year + 1, hios_id: "11111111122302-01", csr_variant_id: "01")
        }

        let(:new_plan) {
          FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01", renewal_plan_id: new_renewal_plan.id)
        }

        let(:elected_plans) { [renewal_plan.id, new_renewal_plan.id] }

        let(:new_enrollment) {
          FactoryGirl.create(:hbx_enrollment,
           household: family.active_household,
           coverage_kind: "health",
           effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
           enrollment_kind: "special_enrollment",
           kind: "employer_sponsored",
           submitted_at: TimeKeeper.date_of_record,
           benefit_group_id: current_benefit_group.id,
           employee_role_id: person.active_employee_roles.first.id,
           benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
           special_enrollment_period_id: sep.id,
           plan_id: new_plan.id,
           aasm_state: 'shopping'
           )
        }

        let(:sep){
          FactoryGirl.create(:special_enrollment_period, family: family)
        }

        it 'should cancel passive renewal and create new passive' do
          passive_renewal = family.enrollments.where(:aasm_state => 'auto_renewing').first
          expect(passive_renewal).not_to be_nil
          new_enrollment.select_coverage!
          family.reload
          passive_renewal.reload
          expect(passive_renewal.coverage_canceled?).to be_truthy
          new_passive = family.enrollments.where(:aasm_state => 'coverage_selected', effective_on: renewing_plan_year.start_on).first
          expect(new_passive.plan).to eq new_renewal_plan
        end

        context 'when employee already has passive renewal coverage' do

          it 'should cancel passive renewal and create new enrollment with coverage selected' do
            passive_renewals = family.enrollments.by_coverage_kind('health').where(:effective_on => renewing_plan_year.start_on)
            expect(passive_renewals.size).to eq 1
            passive_renewal = passive_renewals.first
            expect(passive_renewal.auto_renewing?).to be_truthy

            new_enrollment.select_coverage!
            family.reload
            passive_renewal.reload

            expect(passive_renewal.coverage_canceled?).to be_truthy
            new_passives = family.enrollments.by_coverage_kind('health').where(:effective_on => renewing_plan_year.start_on, :id.ne => passive_renewal.id)
            expect(new_passives.size).to eq 1
            expect(new_passives.first.coverage_selected?).to be_truthy
          end
        end

        context 'when employee actively renewed coverage' do

          it 'should not cancel active renewal and should not generate passive' do
            renewal_coverage = family.enrollments.by_coverage_kind('health').where(:aasm_state => 'auto_renewing').first
            renewal_coverage.update(aasm_state: 'coverage_selected')

            new_enrollment.select_coverage!
            family.reload
            renewal_coverage.reload

            expect(renewal_coverage.coverage_canceled?).to be_falsey
            new_passive = family.enrollments.by_coverage_kind('health').where(:aasm_state => 'auto_renewing').first
            expect(new_passive.blank?).to be_truthy
          end
        end
      end

      context 'when EE terminates current coverage' do

        it 'should cancel passive renewal and generate a waiver' do
          passive_renewal = family.enrollments.where(:aasm_state => 'auto_renewing').first
          expect(passive_renewal).not_to be_nil

          enrollment.terminate_coverage!
          enrollment.update_renewal_coverage

          expect(passive_renewal.coverage_canceled?).to be_truthy
          passive_waiver = family.enrollments.where(:aasm_state => 'renewing_waived').first
          expect(passive_waiver.present?).to be_truthy
        end
      end
    end
  end

  context '#is_applicable_for_renewal' do
    let(:benefit_group) { double("BenefitGroup", :plan_year => double("PlanYear", :is_published? => true))}
    let(:enrollment) { FactoryGirl.build_stubbed(:hbx_enrollment)}
    it "should return false if benefit group is nil for shop enrollment" do
      expect(enrollment.is_applicable_for_renewal?).to eq false
    end

    it "should return true if benefit group & published plan year present for shop enrollment" do
      allow(enrollment).to receive(:benefit_group).and_return benefit_group
      expect(enrollment.is_applicable_for_renewal?).to eq true
    end
  end

  context "market_name" do
    it "for shop" do
      enrollment.kind = 'employer_sponsored'
      expect(enrollment.market_name).to eq 'Employer Sponsored'
    end

    it "for individual" do
      enrollment.kind = 'individual'
      expect(enrollment.market_name).to eq 'Individual'
    end
  end
end

describe HbxEnrollment, 'Voiding enrollments', type: :model, dbclean: :after_all do
  let!(:hbx_profile)    { FactoryGirl.create(:hbx_profile) }
  let(:family)          { FactoryGirl.build(:individual_market_family) }
  let(:hbx_enrollment)  { FactoryGirl.build(:hbx_enrollment, :individual_unassisted, household: family.active_household, effective_on: TimeKeeper.date_of_record ) }

  context "Enrollment is in active state" do
    it "enrollment is in coverage_selected state" do
      expect(hbx_enrollment.coverage_selected?).to be_truthy
    end

    context "and the enrollment is invalidated" do
      it "enrollment should transition to void state" do
        hbx_enrollment.invalidate_enrollment!
        expect(HbxEnrollment.find(hbx_enrollment.id).void?).to be_truthy
      end
    end
  end

  context "Enrollment is in terminated state" do
    before do
      hbx_enrollment.terminate_benefit(TimeKeeper.date_of_record - 2.months)
      hbx_enrollment.save!
    end

    # Although slower, it's essential to read the record from DB, as the in-memory version may differ
    it "enrollment is in terminated state" do
      expect(HbxEnrollment.find(hbx_enrollment.id).coverage_terminated?).to be_truthy
    end

    context "and the enrollment is invalidated" do
      before do
        hbx_enrollment.invalidate_enrollment
        hbx_enrollment.save!
      end

      it "enrollment should transition to void state" do
        expect(HbxEnrollment.find(hbx_enrollment.id).void?).to be_truthy
      end

      it "terminated_on value should be null" do
        expect(HbxEnrollment.find(hbx_enrollment.id).terminated_on).to be_nil
      end

      it "terminate_reason value should be null" do
        expect(HbxEnrollment.find(hbx_enrollment.id).terminate_reason).to be_nil
      end
    end
  end
end

describe HbxEnrollment, 'Renewal Purchase', type: :model, dbclean: :after_all do
  let(:family)          { FactoryGirl.build(:individual_market_family) }
  let(:hbx_enrollment)  { FactoryGirl.build(:hbx_enrollment, :individual_unassisted, household: family.active_household, kind: 'individual') }

  context "open enrollment" do
    before do
      hbx_enrollment.update(enrollment_kind: 'open_enrollment')
    end

    it "should return true when auto_renewing" do
      FactoryGirl.build(:hbx_enrollment, :individual_unassisted, household: family.active_household, aasm_state: 'auto_renewing')
      expect(hbx_enrollment.is_active_renewal_purchase?).to be_truthy
    end

    it "should return true when renewing_coverage_selected" do
      FactoryGirl.build(:hbx_enrollment, :individual_unassisted, household: family.active_household, aasm_state: 'renewing_coverage_selected')
      expect(hbx_enrollment.is_active_renewal_purchase?).to be_truthy
    end

    it "should return false when coverage_selected" do
      FactoryGirl.build(:hbx_enrollment, :individual_unassisted, household: family.active_household, aasm_state: 'coverage_selected')
      expect(hbx_enrollment.is_active_renewal_purchase?).to be_falsey
    end
  end

  it "should return false when it is not open_enrollment" do
    hbx_enrollment.update(enrollment_kind: 'special_enrollment')
    expect(hbx_enrollment.is_active_renewal_purchase?).to be_falsey
  end

  it "should return false when it is individual" do
    hbx_enrollment.update(kind: 'employer_sponsored')
    expect(hbx_enrollment.is_active_renewal_purchase?).to be_falsey
  end
end

describe HbxEnrollment, 'state machine' do
  let(:family) { FactoryGirl.build(:individual_market_family) }
  subject { FactoryGirl.build(:hbx_enrollment, :individual_unassisted, household: family.active_household ) }

  events = [:move_to_enrolled, :move_to_contingent, :move_to_pending]

  shared_examples_for "state machine transitions" do |current_state, new_state, event|
    it "transition #{current_state} to #{new_state} on #{event} event" do
      expect(subject).to transition_from(current_state).to(new_state).on_event(event)
    end
  end

  context "move_to_enrolled event" do
    it_behaves_like "state machine transitions", :unverified, :coverage_selected, :move_to_enrolled
    it_behaves_like "state machine transitions", :enrolled_contingent, :coverage_selected, :move_to_enrolled
  end

  context "move_to_contingent event" do
    it_behaves_like "state machine transitions", :shopping, :enrolled_contingent, :move_to_contingent!
    it_behaves_like "state machine transitions", :coverage_selected, :enrolled_contingent, :move_to_contingent!
    it_behaves_like "state machine transitions", :unverified, :enrolled_contingent, :move_to_contingent!
    it_behaves_like "state machine transitions", :coverage_enrolled, :enrolled_contingent, :move_to_contingent!
    it_behaves_like "state machine transitions", :auto_renewing, :enrolled_contingent, :move_to_contingent!
  end

  context "move_to_pending event" do
    it_behaves_like "state machine transitions", :shopping, :unverified, :move_to_pending!
    it_behaves_like "state machine transitions", :coverage_selected, :unverified, :move_to_pending!
    it_behaves_like "state machine transitions", :enrolled_contingent, :unverified, :move_to_pending!
    it_behaves_like "state machine transitions", :coverage_enrolled, :unverified, :move_to_pending!
    it_behaves_like "state machine transitions", :auto_renewing, :unverified, :move_to_pending!
  end
end

describe HbxEnrollment, 'validate_for_cobra_eligiblity' do

  context 'When employee is designated as cobra' do

    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_month }
    let(:cobra_begin_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
    let(:hbx_enrollment) { HbxEnrollment.new(kind: 'employer_sponsored', effective_on: effective_on) }
    let(:employee_role) { double(is_cobra_status?: true, census_employee: census_employee)}
    let(:census_employee) { double(cobra_begin_date: cobra_begin_date, have_valid_date_for_cobra?: true, coverage_terminated_on: cobra_begin_date - 1.day)}

    before do
      allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
    end

    context 'When Enrollment Effectve date is prior to cobra begin date' do
      it 'should reset enrollment effective date to cobra begin date' do
        hbx_enrollment.validate_for_cobra_eligiblity(employee_role)
        expect(hbx_enrollment.kind).to eq 'employer_sponsored_cobra'
        expect(hbx_enrollment.effective_on).to eq cobra_begin_date
      end
    end

    context 'When Enrollment Effectve date is after cobra begin date' do
      let(:cobra_begin_date) { TimeKeeper.date_of_record.prev_month.beginning_of_month }

      it 'should not update enrollment effective date' do
        hbx_enrollment.validate_for_cobra_eligiblity(employee_role)
        expect(hbx_enrollment.kind).to eq 'employer_sponsored_cobra'
        expect(hbx_enrollment.effective_on).to eq effective_on
      end
    end

    context 'When employee not elgibile for cobra' do
      let(:census_employee) { double(cobra_begin_date: cobra_begin_date, have_valid_date_for_cobra?: false, coverage_terminated_on: cobra_begin_date - 1.day) }

      it 'should raise error' do
        expect{hbx_enrollment.validate_for_cobra_eligiblity(employee_role)}.to raise_error("You may not enroll for cobra after #{Settings.aca.shop_market.cobra_enrollment_period.months} months later of coverage terminated.")
      end
    end
  end
end

describe HbxEnrollment, '.build_plan_premium', type: :model, dbclean: :after_all do
  let!(:employer_profile) { create(:employer_with_planyear, plan_year_state: 'active')}
  let(:benefit_group) { employer_profile.published_plan_year.benefit_groups.first}

  let!(:census_employees){
    FactoryGirl.create :census_employee, :owner, employer_profile: employer_profile
    employee = FactoryGirl.create :census_employee, employer_profile: employer_profile
    employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
  }

  let!(:plan) {
    FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: benefit_group.start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01")
  }

  let(:ce) { employer_profile.census_employees.non_business_owner.first }

  let!(:family) {
    person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
  }

  let(:person) { family.primary_applicant.person }

  context 'Employer Sponsored Coverage' do
    let!(:enrollment) {
      FactoryGirl.create(:hbx_enrollment,
       household: family.active_household,
       coverage_kind: "health",
       effective_on: benefit_group.start_on,
       enrollment_kind: "open_enrollment",
       kind: "employer_sponsored",
       benefit_group_id: benefit_group.id,
       employee_role_id: person.active_employee_roles.first.id,
       benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
       plan_id: plan.id
       )
    }

    context 'for congression employer' do
      before do
        allow(enrollment).to receive_message_chain("benefit_group.is_congress") { true }
      end

      it "should build premiums" do
        plan = enrollment.build_plan_premium(qhp_plan: plan)
        expect(plan).to be_kind_of(PlanCostDecoratorCongress)
      end
    end

    context 'for non congression employer' do
      it "should build premiums" do
        plan = enrollment.build_plan_premium(qhp_plan: plan)
        expect(plan).to be_kind_of(PlanCostDecorator)
      end
    end
  end

  context 'Individual Coverage' do
    let!(:enrollment) {
      FactoryGirl.create(:hbx_enrollment,
       household: family.active_household,
       coverage_kind: "health",
       effective_on: TimeKeeper.date_of_record.beginning_of_month,
       enrollment_kind: "open_enrollment",
       kind: "individual",
       plan_id: plan.id
       )
    }

    it "should build premiums" do
      plan = enrollment.build_plan_premium(qhp_plan: plan)
      expect(plan).to be_kind_of(UnassistedPlanCostDecorator)
    end
  end
end

describe HbxEnrollment, dbclean: :after_all do
  include_context "BradyWorkAfterAll"

  before :all do
    create_brady_census_families
  end

  context "Cancel / Terminate Previous Enrollments for Shop" do
    let(:household) {mikes_family.households.first}
    let(:coverage_household) {household.coverage_households.first}
    let(:family) {FactoryGirl.build(:family)}

    before :each do
      allow(coverage_household).to receive(:household).and_return household
      allow(household).to receive(:family).and_return family
      @enrollment1 = household.create_hbx_enrollment_from(employee_role: mikes_employee_role, coverage_household: coverage_household, benefit_group: mikes_benefit_group, benefit_group_assignment: @mikes_benefit_group_assignments)
      @enrollment1.aasm_state = "coverage_selected"
      @enrollment1.save
      @enrollment2 = household.create_hbx_enrollment_from(employee_role: mikes_employee_role, coverage_household: coverage_household, benefit_group: mikes_benefit_group, benefit_group_assignment: @mikes_benefit_group_assignments)
      @enrollment2.save
    end

    it "should cancel the previous enrollment if the effective_on date of the previous and the current are the same." do
      @enrollment2.update_existing_shop_coverage
      expect(@enrollment1.aasm_state).to eq "coverage_canceled"
    end
  end

  context "Cancel / Terminate Previous Enrollments for IVL" do
    attr_reader :enrollment, :household, :coverage_household

    let(:consumer_role) {FactoryGirl.create(:consumer_role)}
    let(:hbx_profile) { FactoryGirl.create(:hbx_profile) }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
    let(:family) {FactoryGirl.build(:family)}

    before :each do
      @household = mikes_family.households.first
      @coverage_household = household.coverage_households.first
      allow(benefit_coverage_period).to receive(:earliest_effective_date).and_return TimeKeeper.date_of_record
      allow(coverage_household).to receive(:household).and_return household
      allow(household).to receive(:family).and_return family
      allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
      @enrollment1 = household.create_hbx_enrollment_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package)
      @enrollment1.update_current( aasm_state: "coverage_selected", enrollment_signature: "somerandomthing!", effective_on: TimeKeeper.date_of_record.beginning_of_month                        )
      @enrollment2 = household.create_hbx_enrollment_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package)
      @enrollment2.update_current(enrollment_signature: "somerandomthing!", effective_on: TimeKeeper.date_of_record.beginning_of_month)
    end

    it "should cancel the previous enrollment if the effective_on date of the previous and the current are the same." do
      @enrollment2.cancel_previous(TimeKeeper.date_of_record.year)
      expect(@enrollment1.aasm_state).to eq "coverage_canceled"
    end
  end

  # describe "#trigger ee_plan_selection_confirmation_sep_new_hire" do
  #   let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: @household, kind: "employer_sponsored", employee_role_id: employee_role.id) }
  #   let(:census_employee) { FactoryGirl.create(:census_employee)  }
  #   let(:employee_role){FactoryGirl.build(:employee_role, :census_employee => census_employee)}

  #   before :each do
  #     @household = mikes_family.households.first
  #   end

  #   it "should trigger ee_plan_selection_confirmation_sep_new_hire job in queue" do
  #     allow(hbx_enrollment).to receive(:census_employee).and_return(census_employee)
  #     allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
  #     allow(employee_role).to receive(:is_under_open_enrollment?).and_return(false)
  #     ActiveJob::Base.queue_adapter = :test
  #     ActiveJob::Base.queue_adapter.enqueued_jobs = []

  #     hbx_enrollment.ee_plan_selection_confirmation_sep_new_hire
  #     queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
  #       job_info[:job] == ShopNoticesNotifierJob
  #     end

  #     expect(queued_job[:args]).not_to be_empty
  #     expect(queued_job[:args].include?('ee_plan_selection_confirmation_sep_new_hire')).to be_truthy
  #     expect(queued_job[:args].include?("#{hbx_enrollment.census_employee.id.to_s}")).to be_truthy
  #     expect(queued_job[:args].third["hbx_enrollment"]).to eq hbx_enrollment.hbx_id.to_s
  #   end
  # end

  # describe "#trigger notify_employee_confirming_coverage_termination" do
  #   let(:family) { FactoryGirl.build(:family, :with_primary_family_member_and_dependent)}
  #   let(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: "employer_sponsored", employee_role_id: employee_role.id) }
  #   let(:census_employee) { FactoryGirl.create(:census_employee)  }
  #   let(:employee_role){FactoryGirl.build(:employee_role, :census_employee => census_employee)}

  #   before :each do
  #     allow(hbx_enrollment).to receive(:census_employee).and_return(census_employee)
  #     allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
  #     allow(hbx_enrollment).to receive(:is_shop?).and_return(true)
  #   end

  #   it "should trigger notify_employee_confirming_coverage_termination job in queue" do
  #     ActiveJob::Base.queue_adapter = :test
  #     ActiveJob::Base.queue_adapter.enqueued_jobs = []
  #     hbx_enrollment.notify_employee_confirming_coverage_termination
  #     queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
  #       job_info[:job] == ShopNoticesNotifierJob
  #     end
  #     expect(queued_job[:args]).not_to be_empty
  #     expect(queued_job[:args].include?('notify_employee_confirming_coverage_termination')).to be_truthy
  #     expect(queued_job[:args].include?("#{hbx_enrollment.census_employee.id.to_s}")).to be_truthy
  #     expect(queued_job[:args].third["hbx_enrollment_hbx_id"]).to eq hbx_enrollment.hbx_id.to_s
  #   end
  # end
end

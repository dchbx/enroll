require 'rails_helper'

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
      before :all do
        @enrollment4 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments
        )
        @enrollment4.save
        @enrollment5 = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments

        )
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

    context "find_by_benefit_group_assignments" do
      before :all do
        3.times.each do
          enrollment = household.create_hbx_enrollment_from(
            employee_role: mikes_employee_role,
            coverage_household: coverage_household,
            benefit_group: mikes_benefit_group,
            benefit_group_assignment: @mikes_benefit_group_assignments
          )
          enrollment.save
        end
      end

      it "should find more than 3 hbx_enrollments" do
        expect(HbxEnrollment.find_by_benefit_group_assignments([@mikes_benefit_group_assignments]).count).to be >= 3
      end

      it "should return empty array without params" do
        expect(HbxEnrollment.find_by_benefit_group_assignments().count).to eq 0
        expect(HbxEnrollment.find_by_benefit_group_assignments()).to eq []
      end

    end

    context "find_by_benefit_group_assignments" do
      before :all do
        enrollment = household.create_hbx_enrollment_from(
          employee_role: mikes_employee_role,
          coverage_household: coverage_household,
          benefit_group: mikes_benefit_group,
          benefit_group_assignment: @mikes_benefit_group_assignments
        )
        enrollment.aasm_state = "auto_renewing"
        enrollment.is_active = false
        enrollment.save
      end

      it "should return an auto renewing enrollment if there exists one" do
        expect(HbxEnrollment.find_by_benefit_group_assignments([@mikes_benefit_group_assignments]).map(&:aasm_state)).to include "auto_renewing"
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
          allow(renewal_bcp).to receive(:open_enrollment_contains?).and_return false
          allow(benefit_sponsorship).to receive(:benefit_coverage_period_by_effective_date).and_return(bcp)
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

    it "when qle is false" do
      allow(family).to receive(:is_under_special_enrollment_period?).and_return true
      enrollment = HbxEnrollment.new_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package, qle: false)
      expect(enrollment.enrollment_kind).to eq "open_enrollment"
    end

    it "when qle is true" do
      allow(family).to receive(:is_under_special_enrollment_period?).and_return true
      enrollment = HbxEnrollment.new_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package, qle: true)
      expect(enrollment.enrollment_kind).to eq "special_enrollment"
    end

    it "when qle is false and is not uder opent enrollment period" do
      allow(family).to receive(:is_under_ivl_open_enrollment?).and_return false
      expect{HbxEnrollment.new_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package, qle: false)}.to raise_error(RuntimeError)
    end

    it "should have submitted at as current date and time" do
      allow(family).to receive(:is_under_special_enrollment_period?).and_return true

      enrollment = HbxEnrollment.new_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package, qle: false, submitted_at: nil)
      enrollment.save
      expect(enrollment.submitted_at).not_to be_nil
    end
  end

  context "coverage_year" do
    let(:date){ TimeKeeper.date_of_record }
    let(:plan_year){ PlanYear.new(start_on: date) }
    let(:benefit_group){ BenefitGroup.new(plan_year: plan_year) }
    let(:plan){ Plan.new(active_year: date.year) }
    let(:hbx_enrollment){ HbxEnrollment.new(benefit_group: benefit_group, kind: "employer_sponsored", plan: plan) }

    it "should return plan year start on year when shop" do
      expect(hbx_enrollment.coverage_year).to eq date.year
    end

    it "should return plan year when ivl" do
      allow(hbx_enrollment).to receive(:kind).and_return("")
      expect(hbx_enrollment.coverage_year).to eq hbx_enrollment.plan.active_year
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
    let(:plan_year){ PlanYear.new(start_on: date) }
    let(:benefit_group){ BenefitGroup.new(plan_year: plan_year) }
    let!(:carrier_profile1) {FactoryGirl.build(:carrier_profile)}
    let!(:carrier_profile2) {FactoryGirl.create(:carrier_profile, organization: organization)}
    let!(:organization) { FactoryGirl.create(:organization, legal_name: "CareFirst", dba: "care")}
    let(:plan1){ Plan.new(active_year: date.year, market: "individual", carrier_profile: carrier_profile1) }
    let(:plan2){ Plan.new(active_year: date.year, market: "individual", carrier_profile: carrier_profile2) }

    let(:hbx_enrollment1){ HbxEnrollment.new(benefit_group: benefit_group, kind: "unassisted_qhp", plan: plan1, household: family1.latest_household, enrollment_kind: "open_enrollment", aasm_state: 'coverage_selected', consumer_role: person1.consumer_role, enrollment_signature: true) }
    let(:hbx_enrollment2){ HbxEnrollment.new(benefit_group: benefit_group, kind: "unassisted_qhp", plan: plan2, household: family1.latest_household, enrollment_kind: "open_enrollment", aasm_state: 'shopping', consumer_role: person1.consumer_role, enrollment_signature: true, effective_on: TimeKeeper.date_of_record) }

    it "should cancel hbx enrollemnt plan1 from carrier1 when choosing plan2 from carrier2" do
      hbx_enrollment1.effective_on = TimeKeeper.date_of_record + 10.days

      hbx_enrollment2.select_coverage!
      expect(hbx_enrollment1.coverage_canceled?).to be_truthy
      expect(hbx_enrollment2.coverage_selected?).to be_truthy
    end

    it "should terminate hbx enrollemnt plan1 from carrier1 when choosing hbx enrollemnt plan2 from carrier2" do
      hbx_enrollment1.effective_on = TimeKeeper.date_of_record - 10.days
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
end

describe HbxEnrollment, dbclean: :after_each do

  let(:employer_profile)          { FactoryGirl.create(:employer_profile) }

  let(:calender_year) { TimeKeeper.date_of_record.year }

  let(:middle_of_prev_year) { Date.new(calender_year - 1, 6, 10) }
  let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', created_at: middle_of_prev_year, updated_at: middle_of_prev_year, hired_on: middle_of_prev_year) }
  let(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }

  let(:employee_role) {
    person.employee_roles.create(
      employer_profile: employer_profile,
      hired_on: census_employee.hired_on,
      census_employee_id: census_employee.id
    )
  }

  let(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:plan_year_start_on) { Date.new(calender_year, 1, 1) }
  let(:plan_year_end_on) { Date.new(calender_year, 12, 31) }
  let(:open_enrollment_start_on) { Date.new(calender_year - 1, 12, 1) }
  let(:open_enrollment_end_on) { Date.new(calender_year - 1, 12, 10) }
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


  let(:benefit_group_assignment) {
    BenefitGroupAssignment.create({
                                    census_employee: census_employee,
                                    benefit_group: plan_year.benefit_groups.first,
                                    start_on: plan_year_start_on
    })
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
                                              benefit_group_assignment_id: benefit_group_assignment.id
                                              )}


  before do
    TimeKeeper.set_date_of_record_unprotected!(plan_year_start_on + 45.days)

    allow(employee_role).to receive(:benefit_group).and_return(plan_year.benefit_groups.first)
    allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
    allow(shop_enrollment).to receive(:employee_role).and_return(employee_role)
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end

  context ".effective_date_for_enrollment" do
    context 'when new hire' do

      let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: TimeKeeper.date_of_record.beginning_of_month, created_at: TimeKeeper.date_of_record ) }

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
        expect(HbxEnrollment.employee_current_benefit_group(employee_role, shop_enrollment, false)).to eq [plan_year.benefit_groups.first, benefit_group_assignment]
      end
    end
  end
end


describe HbxEnrollment, dbclean: :after_each do

  context ".can_select_coverage?" do
    let(:employer_profile)          { FactoryGirl.create(:employer_profile) }

    let(:calender_year) { TimeKeeper.date_of_record.year }

    let(:middle_of_prev_year) { Date.new(calender_year - 1, 6, 10) }
    let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', created_at: middle_of_prev_year, updated_at: middle_of_prev_year, hired_on: middle_of_prev_year) }
    let(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789') }

    let(:employee_role) {
      person.employee_roles.create(
        employer_profile: employer_profile,
        hired_on: census_employee.hired_on,
        census_employee_id: census_employee.id
      )
    }

    let(:shop_family)       { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:plan_year_start_on) { Date.new(calender_year, 1, 1) }
    let(:plan_year_end_on) { Date.new(calender_year, 12, 31) }
    let(:open_enrollment_start_on) { Date.new(calender_year - 1, 12, 1) }
    let(:open_enrollment_end_on) { Date.new(calender_year - 1, 12, 10) }
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


    let(:benefit_group_assignment) {
      BenefitGroupAssignment.create({
                                      census_employee: census_employee,
                                      benefit_group: plan_year.benefit_groups.first,
                                      start_on: plan_year_start_on
      })
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
                                                 benefit_group_assignment_id: benefit_group_assignment.id
                                                 )
                              }

    before do
      allow(employee_role).to receive(:benefit_group).and_return(plan_year.benefit_groups.first)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      allow(shop_enrollment).to receive(:employee_role).and_return(employee_role)
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
      let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: Date.new(calender_year, 3, 1), created_at: Date.new(calender_year, 2, 1), updated_at: Date.new(calender_year, 2, 1)) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(calender_year, 3, 15))
      end

      it "should allow" do
        expect(shop_enrollment.can_select_coverage?).to be_truthy
      end
    end

    context 'when not a new hire' do
      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(calender_year, 3, 15))
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
      let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: middle_of_prev_year, created_at: Date.new(calender_year, 5, 10), updated_at: Date.new(calender_year, 5, 10)) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(calender_year, 5, 15))
      end

      it "should allow" do
        expect(shop_enrollment.can_select_coverage?).to be_truthy
      end
    end

    context 'when roster update not present' do
      let(:census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: middle_of_prev_year, created_at: middle_of_prev_year, updated_at: Date.new(calender_year, 5, 10)) }

      before do
        TimeKeeper.set_date_of_record_unprotected!(Date.new(calender_year, 5, 9))
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
      let(:new_census_employee) { FactoryGirl.create(:census_employee, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789', hired_on: middle_of_prev_year, created_at: Date.new(calender_year, 5, 10), updated_at: Date.new(calender_year, 5, 10)) }


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
                                                   benefit_group_assignment_id: benefit_group_assignment.id,
                                                   special_enrollment_period_id: special_enrollment_period.id
                                                   )
                                }

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
    let(:ivl_termination_date)  { TimeKeeper.date_of_record + HbxProfile::IndividualEnrollmentTerminationMinimum }

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
    let(:shop_enrollment)   { FactoryGirl.create(:hbx_enrollment,
                                                 household: shop_family.latest_household,
                                                 coverage_kind: "health",
                                                 effective_on: effective_on_date,
                                                 enrollment_kind: "open_enrollment",
                                                 kind: "employer_sponsored",
                                                 submitted_at: effective_on_date - 10.days,
                                                 benefit_group_id: benefit_group.id
                                                 )
                              }

    let(:shop_termination_date)  { TimeKeeper.date_of_record.end_of_month }


    it "should be SHOP enrollment kind" do
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
      subject.benefit_group = BenefitGroup.new({
                                                 :plan_year => PlanYear.new({
                                                                              :open_enrollment_start_on => open_enrollment_start,
                                                                              :open_enrollment_end_on => open_enrollment_end
                                                 })
      })
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
      subject.benefit_group = BenefitGroup.new({
                                                 :plan_year => PlanYear.new({
                                                                              :open_enrollment_start_on => open_enrollment_start,
                                                                              :open_enrollment_end_on => open_enrollment_end,
                                                                              :start_on => coverage_start
                                                 })
      })
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
      rs = HbxEnrollment.find_shop_and_health_by_benefit_group_assignment(enrollment.benefit_group_assignment)
      expect(rs).to include enrollment
    end

    it "should be empty while the enrollment is not health and status is not showing" do
      enrollment.aasm_state = 'shopping'
      enrollment.save
      rs = HbxEnrollment.find_shop_and_health_by_benefit_group_assignment(enrollment.benefit_group_assignment)
      expect(rs).to be_empty
    end

    it "should not return the hbx_enrollments while the enrollment is dental and status is not showing" do
      enrollment.coverage_kind = 'dental'
      enrollment.save
      rs = HbxEnrollment.find_shop_and_health_by_benefit_group_assignment(enrollment.benefit_group_assignment)
      expect(rs).to be_empty
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

describe HbxEnrollment, 'Terminate/Cancel current enrollment when new coverage selected', type: :model, dbclean: :after_all do

  let!(:employer_profile) {
    org = FactoryGirl.create :organization, legal_name: "Corp 1"
    FactoryGirl.create :employer_profile, organization: org
  }

  let(:start_on) { (TimeKeeper.date_of_record + 2.months).beginning_of_month - 1.year }
  let(:end_on) { start_on + 1.year - 1.day }
  let(:open_enrollment_start_on) { start_on - 1.month }
  let(:open_enrollment_end_on) { open_enrollment_start_on + 9.days }

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

    let(:new_enrolllment) {
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

    it 'should terminate their existing coverage' do
      expect(enrollment.coverage_selected?).to be_truthy
      expect(enrollment.terminated_on).to be_nil
      new_enrolllment.select_coverage!
      expect(enrollment.coverage_terminated?).to be_truthy
      expect(enrollment.terminated_on).to eq(new_enrolllment.effective_on - 1.day)
    end
  end


  context 'When family has passive renewal and selected a coverage' do

    let!(:renewing_plan_year) {
      FactoryGirl.create :plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, end_on: end_on + 1.year, open_enrollment_start_on: open_enrollment_start_on + 1.year, open_enrollment_end_on: open_enrollment_end_on + 1.year + 3.days, fte_count: 2, aasm_state: :renewing_published
    }

    let!(:renewal_benefit_group){ FactoryGirl.create :benefit_group, plan_year: renewing_plan_year, reference_plan_id: renewal_plan.id }
    let!(:renewal_benefit_group_assignment) { ce.add_renew_benefit_group_assignment renewal_benefit_group }

    let!(:generate_passive_renewal) {
      factory = Factories::FamilyEnrollmentRenewalFactory.new
      factory.family = family
      factory.census_employee = ce
      factory.employer = employer_profile
      factory.renewing_plan_year = employer_profile.renewing_plan_year
      factory.renew
    }

    let!(:new_plan) {
      FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: start_on.year + 1, hios_id: "11111111122301-01", csr_variant_id: "01")
    }

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
end

describe HbxEnrollment, 'Voiding enrollments', type: :model, dbclean: :after_all do

  let!(:hbx_profile)    { FactoryGirl.create(:hbx_profile) }
  let(:family)          { FactoryGirl.build(:individual_market_family) }
  let(:hbx_enrollment)  { FactoryGirl.build(:hbx_enrollment, :individual_unassisted, household: family.active_household ) }

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

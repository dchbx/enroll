require 'rails_helper'
require 'aasm/rspec'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe HbxEnrollment, type: :model, dbclean: :around_each do

  describe HbxEnrollment, dbclean: :around_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    describe "state transitions" do
      subject { HbxEnrollment.new }
      it "should check for state :actively_renewing" do
        allow(subject).to receive(:propagate_selection).and_return(true)
        expect(subject.aasm.states.map(&:name)).to include :actively_renewing
        expect(subject).to transition_from(:actively_renewing).to(:renewing_coverage_selected).on_event(:select_coverage)
      end
    end

    context "#enrollments_for_display_census_employee_show for displaying individual census employee enrollments on show page" do
      context "no census employee" do
        it "should return blank array" do
          expect(HbxEnrollment.enrollments_for_display_census_employee_show(nil)).to eq([])
        end
      end

      context "census employee has active enrollments not in shopping aasm state" do
        let(:census_employee) { FactoryBot.create(:census_employee_with_active_assignment) }
        let(:census_employee_person) do
          FactoryBot.create(
            :person,
            :with_family,
            first_name: census_employee.first_name,
            last_name: census_employee.last_name,
            ssn: census_employee.ssn,
            dob: census_employee.dob,
            )

        end
        let(:employee_role) { double }
        let!(:employee_role_id) { BSON::ObjectId.new }
        let!(:active_benefit_package) do
          double(id: BSON::ObjectId.new)
        end
        let(:active_benefit_enrollment) { HbxEnrollment.last }
        before do
          census_employee
          census_employee_person
          allow(census_employee).to receive(:employee_role_id).and_return(employee_role_id)
          # Create active enrollment
          census_employee_person.primary_family.hbx_enrollments.build(
            household: census_employee_person.primary_family.active_household,
            kind: "employer_sponsored"
          ).save!
          allow(census_employee).to receive(:active_benefit_group).and_return(active_benefit_package)
          allow(census_employee).to receive(:employee_role).and_return(employee_role)
          # Return query for active benefit enrollment
          allow(HbxEnrollment).to receive(:where).with(
            {
              :"sponsored_benefit_package_id".in => [census_employee.active_benefit_group.try(:id)].compact,
              :"employee_role_id" => census_employee.employee_role_id,
              :"aasm_state".nin => ["shopping", "coverage_terminated", "coverage_expired", "inactive"],
              :"external_enrollment" => false
            }
          ).and_return([active_benefit_enrollment])
        end

        it "should return array of active/renewal/non shopping enrollments" do
          expect(HbxEnrollment.enrollments_for_display_census_employee_show(census_employee)).to include(active_benefit_enrollment)
        end
      end
    end

    context "an employer defines a plan year with multiple benefit groups, adds employees to roster and assigns benefit groups" do

      before do
        white_collar_benefit_group = build(:benefit_sponsors_benefit_packages_benefit_package, health_sponsored_benefit: true, product_package: product_package, benefit_application: initial_application)
        initial_application.benefit_packages << white_collar_benefit_group
        initial_application.save!
      end

      let(:blue_collar_employee_count) {7}
      let(:white_collar_employee_count) {5}
      let(:fte_count) {blue_collar_employee_count + white_collar_employee_count}

      let(:employer_profile) {benefit_sponsorship.profile}
      let(:organization) {employer_profile.organization}

      let(:plan_year) {initial_application}
      let(:blue_collar_benefit_group) {plan_year.benefit_groups[0]}
      let!(:blue_collar_census_employees) { FactoryBot.create_list(:census_employee, blue_collar_employee_count, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship, benefit_group: current_benefit_package)}
      let!(:white_collar_census_employees) {FactoryBot.create_list(:census_employee, white_collar_employee_count, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship, benefit_group: current_benefit_package) }


      it "should have a valid plan year in enrolling state" do
        expect(plan_year.aasm_state).to eq :active
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
          blue_collar_employee_roles.reduce([]) {|list, employee_role| family = Family.find_or_build_from_employee_role(employee_role); list << family}
        end

        let(:white_collar_families) do
          white_collar_employee_roles.reduce([]) {|list, employee_role| family = Family.find_or_build_from_employee_role(employee_role); list << family}
        end

        it "should include the requisite blue collar employee roles and families" do
          expect(blue_collar_employee_roles.size).to eq blue_collar_employee_count
          expect(blue_collar_families.size).to eq blue_collar_employee_count
        end

        it "should include the requisite white collar employee roles and families" do
          expect(white_collar_employee_roles.size).to eq white_collar_employee_count
          expect(white_collar_families.size).to eq white_collar_employee_count
        end
      end
    end
  end

  context "for verifying newly added attribute" do
    let!(:person100)          { FactoryBot.create(:person, :with_consumer_role) }
    let!(:family100)          { FactoryBot.create(:family, :with_primary_family_member, person: person100) }
    let!(:hbx_enrollment100)  { FactoryBot.create(:hbx_enrollment, household: family100.active_household, family: family100) }

    it "should not raise error" do
      expect{hbx_enrollment100.is_any_enrollment_member_outstanding}.not_to raise_error
    end
  end

  describe HbxEnrollment, dbclean: :around_each do

    include_context "BradyWorkAfterAll"

    before :all do
      create_brady_census_families
    end

    context "is created from an employer_profile, benefit_group, and coverage_household" do
    #   attr_reader :enrollment, :household, :coverage_household
    #   before :all do
    #     @household = mikes_family.households.first
    #     @coverage_household = household.coverage_households.first
    #     @enrollment = household.create_hbx_enrollment_from(
    #         employee_role: mikes_employee_role,
    #         coverage_household: coverage_household,
    #         benefit_group: nil,
    #         benefit_group_assignment: @mikes_census_employee.active_benefit_group_assignment,
    #         benefit_package: @mikes_benefit_group,
    #         sponsored_benefit: @mikes_benefit_group.sponsored_benefits.first
    #     )
    #   end

    #   it "should assign the benefit group assignment" do
    #     expect(enrollment.benefit_group_assignment_id).not_to be_nil
    #   end

    #   it "should be employer sponsored" do
    #     expect(enrollment.kind).to eq "employer_sponsored"
    #   end

    #   it "should set the employer_profile" do
    #     expect(enrollment.employer_profile._id).to eq mikes_employer._id
    #   end

    #   it "should be active" do
    #     expect(enrollment.is_active?).to be_truthy
    #   end

    #   it "should be effective when the plan_year starts by default" do
    #     expect(enrollment.effective_on).to eq mikes_plan_year.start_on
    #   end

    #   it "should be valid" do
    #     expect(enrollment.valid?).to be_truthy
    #   end

    #   it "should default to enrolling everyone" do
    #     expect(enrollment.applicant_ids).to match_array(coverage_household.applicant_ids)
    #   end

    #   it "should not return a total premium" do
    #     expect {enrollment.total_premium}.not_to raise_error
    #   end

    #   it "should not return an employee cost" do
    #     expect {enrollment.total_employee_cost}.not_to raise_error
    #   end

    #   it "should not return an employer contribution" do
    #     expect {enrollment.total_employer_contribution}.not_to raise_error
    #   end

    #   context "and the employee enrolls" do
    #     before :all do
    #       enrollment.plan = enrollment.benefit_group.reference_plan
    #       enrollment.save
    #     end

    #     it "should return a total premium" do
    #       Caches::PlanDetails.load_record_cache!
    #       expect(enrollment.total_premium).to be
    #     end

    #     it "should return an employee cost" do
    #       Caches::PlanDetails.load_record_cache!
    #       expect(enrollment.total_employee_cost).to be
    #     end

    #     it "should return an employer contribution" do
    #       Caches::PlanDetails.load_record_cache!
    #       expect(enrollment.total_employer_contribution).to be
    #     end
    #   end

    #   context "update_current" do
    #     before :all do
    #       @enrollment2 = household.create_hbx_enrollment_from(
    #           employee_role: mikes_employee_role,
    #           coverage_household: coverage_household,
    #           benefit_group: mikes_benefit_group,
    #           benefit_group_assignment: @mikes_benefit_group_assignments
    #       )
    #       @enrollment2.save
    #       @enrollment2.update_current(is_active: false)
    #     end

    #     it "enrollment and enrollment2 should have same household" do
    #       expect(@enrollment2.household).to eq enrollment.household
    #     end

    #     it "enrollment2 should be not active" do
    #       expect(@enrollment2.is_active).to be_falsey
    #     end

    #     it "enrollment should be active" do
    #       expect(enrollment.is_active).to be_truthy
    #     end
    #   end

    #   context "inactive_related_hbxs" do
    #     before :all do
    #       @enrollment3 = household.create_hbx_enrollment_from(
    #           employee_role: mikes_employee_role,
    #           coverage_household: coverage_household,
    #           benefit_group: mikes_benefit_group,
    #           benefit_group_assignment: @mikes_benefit_group_assignments
    #       )
    #       @enrollment3.save
    #       @enrollment3.inactive_related_hbxs
    #     end

    #     it "should have an assigned hbx_id" do
    #       expect(@enrollment3.hbx_id).not_to eq nil
    #     end

    #     it "enrollment and enrollment3 should have same household" do
    #       expect(@enrollment3.household).to eq enrollment.household
    #     end

    #     it "enrollment should be not active" do
    #       expect(enrollment.is_active).to be_falsey
    #     end

    #     it "enrollment3 should be active" do
    #       expect(@enrollment3.is_active).to be_truthy
    #     end

    #     it "should only one active when they have same employer" do
    #       hbxs = @enrollment3.household.hbx_enrollments.select do |hbx|
    #         hbx.employee_role.employer_profile_id == @enrollment3.employee_role.employer_profile_id and hbx.is_active?
    #       end
    #       expect(hbxs.count).to eq 1
    #     end
    #   end

    #   context "waive_coverage_by_benefit_group_assignment" do
    #     before :each do
    #       @enrollment4 = household.create_hbx_enrollment_from(
    #           employee_role: mikes_employee_role,
    #           coverage_household: coverage_household,
    #           benefit_group: mikes_benefit_group,
    #           benefit_group_assignment: @mikes_benefit_group_assignments
    #       )
    #       allow(@enrollment4).to receive(:notify_on_save).and_return true
    #       @enrollment4.save
    #       @enrollment5 = household.create_hbx_enrollment_from(
    #           employee_role: mikes_employee_role,
    #           coverage_household: coverage_household,
    #           benefit_group: mikes_benefit_group,
    #           benefit_group_assignment: @mikes_benefit_group_assignments

    #       )
    #       allow(@enrollment5).to receive(:notify_on_save).and_return true
    #       @enrollment5.save
    #       @enrollment4.waive_coverage_by_benefit_group_assignment("start a new job")
    #       @enrollment5.reload
    #     end

    #     it "enrollment4 should be inactive" do
    #       expect(@enrollment4.aasm_state).to eq "inactive"
    #     end

    #     it "enrollment4 should get waiver_reason" do
    #       expect(@enrollment4.waiver_reason).to eq "start a new job"
    #     end

    #     it "enrollment5 should not be waived" do
    #       expect(@enrollment5.aasm_state).to eq "shopping"
    #     end

    #     it "enrollment5 should not have waiver_reason" do
    #       expect(@enrollment5.waiver_reason).to eq nil
    #     end
    #   end

    #   context "should shedule termination previous auto renewing enrollment" do
    #     before :each do
    #       @enrollment6 = household.create_hbx_enrollment_from(
    #           employee_role: mikes_employee_role,
    #           coverage_household: coverage_household,
    #           benefit_group: mikes_benefit_group,
    #           benefit_group_assignment: @mikes_benefit_group_assignments
    #       )
    #       @enrollment6.effective_on=TimeKeeper.date_of_record + 1.days
    #       @enrollment6.aasm_state = "auto_renewing"
    #       allow(@enrollment6).to receive(:notify_on_save).and_return true
    #       @enrollment6.save
    #       @enrollment7 = household.create_hbx_enrollment_from(
    #           employee_role: mikes_employee_role,
    #           coverage_household: coverage_household,
    #           benefit_group: mikes_benefit_group,
    #           benefit_group_assignment: @mikes_benefit_group_assignments
    #       )
    #       allow(@enrollment7).to receive(:notify_on_save).and_return true
    #       @enrollment7.save
    #       @enrollment7.cancel_previous(TimeKeeper.date_of_record.year)
    #     end

    #     it "doesn't move enrollment for shop market" do
    #       expect(@enrollment6.aasm_state).to eq "auto_renewing"
    #     end

    #     it "should not cancel current shopping enrollment" do
    #       expect(@enrollment7.aasm_state).to eq "shopping"
    #     end
    #   end
    end

    context "when market type is individual" do
      let(:person) { FactoryBot.create(:person, :with_consumer_role)}
      let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let!(:tax_household) {FactoryBot.create(:tax_household,  effective_ending_on: nil, household: family.households.first)}
      let!(:household) { family.active_household}
      let!(:eligibility_determination) {FactoryBot.create(:eligibility_determination, csr_eligibility_kind: "csr_87", determined_on: TimeKeeper.date_of_record, tax_household: tax_household)}
      let(:coverage_household) { family.households.first.coverage_households.first }
      let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
      let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
      let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
      let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
      let(:enrollment) {
        enrollment = household.new_hbx_enrollment_from(
          consumer_role: person.consumer_role,
          coverage_household: coverage_household,
          benefit_package: benefit_package,
          qle: true
        )
        enrollment.save
        enrollment
      }
      let(:hbx_enrollment_members) { enrollment.hbx_enrollment_members}
      let(:active_year) {TimeKeeper.date_of_record.year}

      before :each do
        allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
        allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
        allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
      end

      it "should return plans with csr kind when individual market is selected" do
        decorated_plans = enrollment.decorated_elected_plans('health', enrollment.kind)
        expect(decorated_plans). to eq (benefit_coverage_period.elected_plans_by_enrollment_members(hbx_enrollment_members, 'health', tax_household, enrollment.kind))
      end
    end

    context "when outstanding member is present" do
      let(:person)                    { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
      let(:family)                    { FactoryBot.create(:family, :with_primary_family_member, person: person) }
      let(:hbx_profile)               {FactoryBot.create(:hbx_profile)}
      let(:benefit_sponsorship)       { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
      let(:benefit_coverage_period)   { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
      let(:benefit_package)           { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
      let!(:hbx_enrollment)           { FactoryBot.create(:hbx_enrollment, is_any_enrollment_member_outstanding: true, aasm_state: "coverage_selected",
                                          household: family.active_household, kind: "individual", family: family) }
      let!(:hbx_enrollment_member)     { FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, hbx_enrollment: hbx_enrollment) }
      let(:active_year)               {TimeKeeper.date_of_record.year}

      before :each do
        allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
        allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
      end

      it "should check for outstanding members" do
        person.consumer_role.update_attribute("aasm_state","verification_outstanding")
        person.consumer_role.verification_types[2].update_attribute("validation_status","verification_outstanding")
        hbx_enrollment.reload
        expect(hbx_enrollment.is_any_member_outstanding?).to be_truthy
      end
    end

    context "decorated_elected_plans" do
      let(:benefit_package) { BenefitPackage.new }
      let(:consumer_role) { FactoryBot.create(:consumer_role) }
      let(:person) { household.family.primary_applicant.person}
      let(:enrollment) {
        enrollment = household.new_hbx_enrollment_from(
          consumer_role: consumer_role,
          coverage_household: coverage_household,
          benefit_package: benefit_package,
          family: family,
          qle: true
        )
        enrollment.save
        enrollment
      }
      let(:hbx_profile) {double}
      let(:benefit_sponsorship) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, renewal_benefit_coverage_period: renewal_bcp, current_benefit_coverage_period: bcp) }
      let(:renewal_bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months) }
      let(:bcp) { double(earliest_effective_date: TimeKeeper.date_of_record - 2.months) }
      let(:plan) { FactoryBot.create(:plan) }
      let(:plan2) { FactoryBot.create(:plan) }
      let(:plan1) { FactoryBot.create(:plan) }
    #   context "decorated_elected_plans" do
    #     let(:benefit_package) {BenefitPackage.new}
    #     let(:consumer_role) {FactoryBot.create(:consumer_role)}
    #     let(:person) {double(primary_family: family)}
    #     let(:family) {double}
    #     let(:enrollment) {
    #       enrollment = household.new_hbx_enrollment_from(
    #           consumer_role: consumer_role,
    #           coverage_household: coverage_household,
    #           benefit_package: benefit_package,
    #           qle: true
    #       )
    #       enrollment.save
    #       enrollment
    #     }
    #     let(:hbx_profile) {double}
    #     let(:benefit_sponsorship) {double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, renewal_benefit_coverage_period: renewal_bcp, current_benefit_coverage_period: bcp)}
    #     let(:renewal_bcp) {double(earliest_effective_date: TimeKeeper.date_of_record - 2.months)}
    #     let(:bcp) {double(earliest_effective_date: TimeKeeper.date_of_record - 2.months)}
    #     let(:plan) {FactoryBot.create(:plan)}
    #     let(:plan2) {FactoryBot.create(:plan)}

    #     context "when in open enrollment" do
    #       before :each do
    #         allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    #         allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    #         allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
    #         allow(consumer_role).to receive(:person).and_return(person)
    #         allow(coverage_household).to receive(:household).and_return household
    #         allow(household).to receive(:family).and_return family
    #         allow(family).to receive(:is_under_special_enrollment_period?).and_return false
    #         allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
    #         allow(enrollment).to receive(:enrollment_kind).and_return "open_enrollment"
    #       end

    #       it "should return decoratored plans when not in the open enrollment" do
    #         allow(renewal_bcp).to receive(:open_enrollment_contains?).and_return false
    #         allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
    #         allow(bcp).to receive(:elected_plans_by_enrollment_members).and_return [plan]
    #         expect(enrollment.decorated_elected_plans('health').first.class).to eq UnassistedPlanCostDecorator
    #         expect(enrollment.decorated_elected_plans('health').count).to eq 1
    #         expect(enrollment.decorated_elected_plans('health').first.id).to eq plan.id
    #       end

    #       it "should return decoratored plans when in the open enrollment" do
    #         allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(renewal_bcp)
    #         allow(renewal_bcp).to receive(:open_enrollment_contains?).and_return true
    #         allow(renewal_bcp).to receive(:elected_plans_by_enrollment_members).and_return [plan2]
    #         expect(enrollment.decorated_elected_plans('health').first.class).to eq UnassistedPlanCostDecorator
    #         expect(enrollment.decorated_elected_plans('health').count).to eq 1
    #         expect(enrollment.decorated_elected_plans('health').first.id).to eq plan2.id
    #       end
    #     end

    #     context "when in special enrollment" do
    #       let(:sep) {SpecialEnrollmentPeriod.new(effective_on: TimeKeeper.date_of_record)}
    #       before :each do
    #         allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    #         allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    #         allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
    #         allow(consumer_role).to receive(:person).and_return(person)
    #         allow(coverage_household).to receive(:household).and_return household
    #         allow(household).to receive(:family).and_return family
    #         allow(family).to receive(:current_sep).and_return sep
    #         allow(family).to receive(:current_special_enrollment_periods).and_return [sep]
    #         allow(family).to receive(:is_under_special_enrollment_period?).and_return true
    #         allow(enrollment).to receive(:enrollment_kind).and_return "special_enrollment"
    #       end

    #       it "should return decoratored plans when not in the open enrollment" do
    #         enrollment.update_attributes(effective_on: sep.effective_on - 1.month)
    #         allow(renewal_bcp).to receive(:open_enrollment_contains?).and_return false
    #         allow(benefit_sponsorship).to receive(:benefit_coverage_period_by_effective_date).with(enrollment.effective_on).and_return(bcp)
    #         allow(bcp).to receive(:elected_plans_by_enrollment_members).and_return [plan]
    #         expect(enrollment.decorated_elected_plans('health').first.class).to eq UnassistedPlanCostDecorator
    #         expect(enrollment.decorated_elected_plans('health').count).to eq 1
    #         expect(enrollment.decorated_elected_plans('health').first.id).to eq plan.id
    #         expect(enrollment.created_at).not_to be_nil
    #       end
    #     end
    #   end


      context "enrollment_kind" do
        let(:person) { FactoryBot.create(:person, :with_consumer_role)}
        let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
        let(:hbx_enrollment) {HbxEnrollment.new(family: family)}
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
    end

    context "#propogate_waiver", dbclean: :around_each do
      let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
      let(:census_employee) {FactoryBot.create(:census_employee)}
      let(:benefit_group_assignment) {FactoryBot.create(:benefit_group_assignment, benefit_group: package, census_employee: census_employee)}
      let(:application) {double(:start_on => TimeKeeper.date_of_record.beginning_of_month, :end_on => (TimeKeeper.date_of_record.beginning_of_month + 1.year) - 1.day, :aasm_state => :active)}
      let(:package) {double("BenefitPackage", :is_a? => BenefitSponsors::BenefitPackages::BenefitPackage, :_id => "id", :plan_year => application, :benefit_application => application, start_on: Date.new(Time.current.year,4,1),end_on: Date.new(2020,3,31))}
      let(:ivl_enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, household: family.active_household, family: family)}
      let(:existing_shop_enrollment) {FactoryBot.create(:hbx_enrollment, :shop, household: family.active_household, family: family)}
      let(:enrollment_for_waiver) {FactoryBot.create(:hbx_enrollment, household: family.active_household, predecessor_enrollment_id: existing_shop_enrollment.id, benefit_group_assignment_id: benefit_group_assignment.id, family: family)}

      before do
        allow(census_employee).to receive(:benefit_group_assignments).and_return [benefit_group_assignment]
        # allow(package).to receive(:start_on).and_return :start_on_1
      end

      it "should return false if it is an ivl enrollment" do
        expect(ivl_enrollment.propogate_waiver).to eq false
      end

      it "should return true for shop enrollment" do
        expect(enrollment_for_waiver.propogate_waiver).to eq true
      end

      it "should waive the benefit group assignment if enrollment belongs to health & shop" do
        enrollment_for_waiver.propogate_waiver
        benefit_group_assignment.reload
        expect(benefit_group_assignment.aasm_state).to eq "coverage_waived"
      end

      it "should not waive the benefit group assignment if enrollment belongs to dental" do
        enrollment_for_waiver.update_attribute(:coverage_kind, "dental")
        enrollment_for_waiver.propogate_waiver
        expect(benefit_group_assignment.aasm_state).not_to eq "coverage_waived"
      end
    end
  end

  describe HbxProfile, 'class methods', type: :model, dbclean: :around_each do

    # before :all do
    #   create_brady_census_families
    # end

    # context "#find" do
    #   it "should return nil with invalid id" do
    #     expect(HbxEnrollment.find("text")).to eq nil
    #   end
    # end

    context "new_from" do
      include_context "BradyWorkAfterAll"

      attr_reader :household, :coverage_household

      before :all do
        create_brady_coverage_households
        @household = mikes_family.households.first
        @coverage_household = household.coverage_households.first
      end

      let(:benefit_package) {BenefitPackage.new}
      let(:consumer_role) {FactoryBot.create(:consumer_role)}
      let(:person) {double(primary_family: family)}
      let(:family) {@household.family}
      let(:sep) {SpecialEnrollmentPeriod.new(effective_on: TimeKeeper.date_of_record)}
      let(:hbx_profile) {double}
      let(:benefit_sponsorship) {double(earliest_effective_date: TimeKeeper.date_of_record - 2.months, renewal_benefit_coverage_period: renewal_bcp, current_benefit_coverage_period: bcp)}
      let(:bcp) {double(earliest_effective_date: TimeKeeper.date_of_record - 2.months)}
      let(:renewal_bcp) {double(earliest_effective_date: TimeKeeper.date_of_record - 2.months)}

      before :each do
        allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
        allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
        allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
        allow(consumer_role).to receive(:person).and_return(person)
        allow(household).to receive(:family).and_return family
        allow(mikes_family).to receive(:is_under_ivl_open_enrollment?).and_return true
        allow(mikes_family).to receive(:current_sep).and_return sep
      end

      shared_examples_for "new enrollment from" do |qle, sep, enrollment_period, error|
        context "#{enrollment_period} period" do
          let(:enrollment) {HbxEnrollment.new_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package, qle: qle)}
          before :each do
            allow(mikes_family).to receive(:is_under_special_enrollment_period?).and_return sep
            allow(mikes_family).to receive(:is_under_ivl_open_enrollment?).and_return enrollment_period == "open_enrollment"
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
              expect {HbxEnrollment.new_from(consumer_role: consumer_role, coverage_household: coverage_household, benefit_package: benefit_package, qle: false)}.to raise_error(RuntimeError)
            end
          end
        end
      end

      it_behaves_like "new enrollment from", false, true, "open_enrollment", false
      it_behaves_like "new enrollment from", true, true, "special_enrollment", false
      it_behaves_like "new enrollment from", false, false, "not_open_enrollment", "raise_an_error"
    end


    context "is reporting a qle before the employer plan start_date and having a expired plan year" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup renewal application"

      let(:predecessor_state)       { :expired }
      let(:renewal_state)           { :active }
      let(:renewal_effective_date)  { TimeKeeper.date_of_record.prev_month.beginning_of_month }

      let(:coverage_household) {double}
      let(:coverage_household_members) {double}
      let(:household) {FactoryBot.create(:household, family: family)}
      let(:qle_kind) {FactoryBot.create(:qualifying_life_event_kind, :effective_on_event_date)}

      let(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile) }
      let(:employee_role) { FactoryBot.create(:employee_role, person: person, census_employee: census_employee, employer_profile: benefit_sponsorship.profile) }

      let(:person) {FactoryBot.create(:person)}
      let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
      let(:sep) {
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
        renewal_application
        allow(coverage_household).to receive(:household).and_return family.active_household
        allow(coverage_household).to receive(:coverage_household_members).and_return []
        allow(sep).to receive(:is_active?).and_return true
        allow(family).to receive(:is_under_special_enrollment_period?).and_return true
        expired_py = benefit_sponsorship.benefit_applications.where(aasm_state: 'expired').first

        census_employee.benefit_group_assignments << BenefitGroupAssignment.new(benefit_group: expired_py.benefit_packages[0], start_on: expired_py.start_on)
        census_employee.update_attributes(:employee_role_id => employee_role.id, hired_on: TimeKeeper.date_of_record - 2.months)
        census_employee.update_attribute(:ssn, census_employee.employee_role.person.ssn)
      end

      it "should return a sep with an effective date that equals to sep date" do
        enrollment = HbxEnrollment.new_from(employee_role: employee_role, coverage_household: coverage_household, benefit_group: nil, benefit_package: nil, benefit_group_assignment: nil, qle: true)
        expect(enrollment.effective_on).to eq sep.qle_on
      end
    end

    context "coverage_year" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:date) {TimeKeeper.date_of_record}
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }

      let(:sponsored_benefit_package) { initial_application.benefit_packages[0] }
      let(:plan) {Plan.new(active_year: date.year)}
      let(:hbx_enrollment) {HbxEnrollment.new(sponsored_benefit_package_id: sponsored_benefit_package.id, effective_on: current_effective_date, kind: "employer_sponsored", plan: plan)}

      it "should return plan year start on year when shop" do
        expect(hbx_enrollment.coverage_year).to eq current_effective_date.year
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

    # TODO - reimplement this spec
    context "calculate_effective_on_from" do
      let(:date) {TimeKeeper.date_of_record}
      let(:family) {double(current_sep: double(effective_on: date), is_under_special_enrollment_period?: true)}
      let(:hbx_profile) {double}
      let(:benefit_sponsorship) {double}
      let(:bcp) {double}
      let(:benefit_group) { double }
      let(:census_employee) { double }
      let(:employee_role) { double(hired_on: date, census_employee: census_employee) }

      before :each do
        allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
        allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
        allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(bcp)
      end

      context "shop" do
        it "special_enrollment" do
          expect(HbxEnrollment.calculate_effective_on_from(market_kind: 'shop', qle: true, family: family, employee_role: nil, benefit_group: benefit_group, benefit_sponsorship: nil)).to eq date
        end

        it "open_enrollment" do
          effective_on = date - 10.days
          allow(census_employee).to receive(:coverage_effective_on).and_return(effective_on)
          allow(family).to receive(:is_under_special_enrollment_period?).and_return(false)
          expect(HbxEnrollment.calculate_effective_on_from(market_kind: 'shop', qle: false, family: family, employee_role: employee_role, benefit_group: benefit_group, benefit_sponsorship: nil)).to eq effective_on
        end
      end

      context "individual" do
        it "special_enrollment" do
          expect(HbxEnrollment.calculate_effective_on_from(market_kind: 'individual', qle: true, family: family, employee_role: nil, benefit_group: nil, benefit_sponsorship: nil)).to eq date
        end

        it "open_enrollment" do
          effective_on = date - 10.days
          allow(bcp).to receive(:earliest_effective_date).and_return effective_on
          allow(family).to receive(:is_under_special_enrollment_period?).and_return(false)
          expect(HbxEnrollment.calculate_effective_on_from(market_kind: 'individual', qle: false, family: family, employee_role: nil, benefit_group: nil, benefit_sponsorship: benefit_sponsorship)).to eq effective_on
        end
      end
    end

    if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
        context "ivl user switching plan from one carrier to other carrier previous hbx_enrollment aasm_sate should be cancel/terminate in DB." do
          let(:person1) {FactoryBot.create(:person, :with_consumer_role)}
          let(:family1) {FactoryBot.create(:family, :with_primary_family_member, :person => person1)}
          let(:household) {FactoryBot.create(:household, family: family1)}
          let(:date) {TimeKeeper.date_of_record}
          let!(:organization) {FactoryBot.create(:organization, legal_name: "CareFirst", dba: "care")}
          let!(:carrier_profile1) {FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)}
          let!(:carrier_profile2) {FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)}
          let!(:product1) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
          let!(:product2) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
          let(:hbx_enrollment1) do
            FactoryBot.create(:hbx_enrollment,
                              kind: "individual",
                              product: product1,
                              household: family1.latest_household,
                              effective_on: TimeKeeper.date_of_record.beginning_of_year,
                              enrollment_kind: "open_enrollment",
                              family: family1,
                              aasm_state: 'coverage_selected',
                              consumer_role: person1.consumer_role,
                              enrollment_signature: true)
          end
          let(:hbx_enrollment2) do
            FactoryBot.create(:hbx_enrollment,
                              kind: 'individual',
                              product: product2,
                              family: family1,
                              household: family1.latest_household,
                              effective_on: TimeKeeper.date_of_record.beginning_of_year,
                              enrollment_kind: 'open_enrollment',
                              aasm_state: 'shopping',
                              consumer_role: person1.consumer_role,
                              enrollment_signature: true,
                              effective_on: date)
          end

          it "should cancel hbx enrollemnt plan1 from carrier1 when choosing plan2 from carrier2" do
            hbx_enrollment1.update_attributes!(effective_on: date + 1.day)
            hbx_enrollment2.effective_on = date
            # This gets processed on 31st Dec
            if hbx_enrollment1.effective_on.year != hbx_enrollment2.effective_on.year
              hbx_enrollment1.effective_on = date + 2.day
              hbx_enrollment2.effective_on = date + 1.day
            end

            hbx_enrollment2.select_coverage!
            hbx_enrollment1_from_db = HbxEnrollment.by_hbx_id(hbx_enrollment1.hbx_id).first.reload
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
            hbx_enrollment1.update_attributes!(effective_on: date + 1.days)
            hbx_enrollment2.update_attributes!(effective_on: date + 20.days)
            hbx_enrollment2.select_coverage!
            expect(hbx_enrollment1.reload.coverage_terminated?).to be_truthy
            expect(hbx_enrollment2.coverage_selected?).to be_truthy
            expect(hbx_enrollment1.terminated_on).to eq hbx_enrollment2.effective_on - 1.day
          end
        end
    end

  describe "when market type is individual" do
    let(:person) { FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let(:coverage_household) { family.households.first.coverage_households.first }
    let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
    let(:verification_attr) { OpenStruct.new({ :determined_at => Time.zone.now, :vlp_authority => "hbx" })}
    let(:active_year) {TimeKeeper.date_of_record.year}
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
    let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
    let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
    let(:benefit_package) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first }
    let(:enrollment) {
      enrollment = family.latest_household.new_hbx_enrollment_from(
          consumer_role: person.consumer_role,
          coverage_household: coverage_household,
          benefit_package: benefit_package,
          qle: true
      )
      enrollment.save
      enrollment
    }
    let(:hbx_enrollment_members) { enrollment.hbx_enrollment_members}

    before :each do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
      allow(enrollment). to receive(:product).and_return product
      allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
      enrollment.update_attributes!(product_id: product.id)
    end

    context "ivl consumer role with unverified state purchased a plan" do
      it "should return enrollment status as unverified" do
        person.consumer_role.update_attribute("aasm_state","unverified")
        enrollment.select_coverage!
        enrollment.reload
        expect(person.consumer_role.aasm_state).to eq "ssa_pending"
        expect(enrollment.coverage_selected?).to be_falsy
        expect(enrollment.aasm_state).to eq "unverified"
      end
    end

    context "ivl user in fully verified state." do
      it "should return enrollment status as coverage_selected" do
        person.consumer_role.update_attribute("aasm_state","fully_verified")
        enrollment.select_coverage!
        enrollment.reload
        expect(person.consumer_role.aasm_state).to eq "fully_verified"
        expect(enrollment.coverage_selected?).to be_truthy
        expect(enrollment.aasm_state).to eq "coverage_selected"
      end
    end

    context "ivl user in verification outstanding state." do
      it "should return enrollment status as coverage_selected and set is_any_enrollment_member_outstanding to true " do
        enrollment.select_coverage!
        person.consumer_role.ssn_invalid!(verification_attr)
        enrollment.reload
        expect(enrollment.coverage_selected?).to eq true
        expect(enrollment.aasm_state).to eq "coverage_selected"
        expect(enrollment.is_any_enrollment_member_outstanding?). to be_truthy
      end
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

    context "cancel_coverage!" do
      let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
      let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, household: family.active_household, family: family, aasm_state: "inactive")}

      it "should cancel the enrollment" do
        hbx_enrollment.cancel_coverage!
        expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
      end

      it "should not populate the terminated on" do
        hbx_enrollment.cancel_coverage!
        expect(hbx_enrollment.terminated_on).to eq nil
      end
    end

    context "cancel_for_non_payment!" do
      let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
      let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, household: family.active_household, aasm_state: "inactive", family: family)}

      it "should cancel the enrollment" do
        hbx_enrollment.cancel_for_non_payment!
        expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
      end

      it "should not populate the terminated on" do
        hbx_enrollment.cancel_for_non_payment!
        expect(hbx_enrollment.terminated_on).to eq nil
      end
    end

    context "terminate_for_non_payment!" do
      let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
      let(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, household: family.active_household, family: family,aasm_state: "coverage_selected")}

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

  describe HbxEnrollment, dbclean: :around_each do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    context ".can_select_coverage?" do
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:effective_on) { current_effective_date }
      let(:hired_on) { TimeKeeper.date_of_record - 3.months }
      let(:employee_created_at) { hired_on }
      let(:employee_updated_at) { employee_created_at }

      let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
      let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}

      let(:aasm_state) { :active }
      let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let(:shop_enrollment) { FactoryBot.create(:hbx_enrollment,
                                                household: shop_family.latest_household,
                                                coverage_kind: "health",
                                                family: shop_family,
                                                effective_on: effective_on,
                                                enrollment_kind: enrollment_kind,
                                                kind: "employer_sponsored",
                                                submitted_at: effective_on - 10.days,
                                                benefit_sponsorship_id: benefit_sponsorship.id,
                                                sponsored_benefit_package_id: current_benefit_package.id,
                                                sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                                                employee_role_id: employee_role.id,
                                                benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                                special_enrollment_period_id: special_enrollment_period_id
      )
      }

      context 'under open enrollment' do
        let(:current_effective_date) { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
        let(:aasm_state) { :enrollment_open }
        let(:hired_on) { TimeKeeper.date_of_record.prev_year }
        let(:open_enrollment_period)  { TimeKeeper.date_of_record..(effective_period.min - 10.days) }

        it "should allow" do
          expect(shop_enrollment.can_select_coverage?).to be_truthy
        end
      end

      context 'outside open enrollment' do
        let(:hired_on) { TimeKeeper.date_of_record.prev_year }

        it "should not allow" do
          expect(shop_enrollment.can_select_coverage?).to be_falsey
        end
      end

      context 'when its a new hire' do
        let(:effective_on) { hired_on.next_month.beginning_of_month }
        let(:hired_on) { TimeKeeper.date_of_record }

        it "should allow" do
          expect(shop_enrollment.can_select_coverage?).to be_truthy
        end
      end

      context 'when not a new hire' do

        it "should not allow" do
          expect(shop_enrollment.can_select_coverage?).to be_falsey
        end

        # TODO: code commented out in hbx_enrollment model. code needs to be enabled before adding this spec back.
        # it "should get a error msg" do
        #   shop_enrollment.can_select_coverage?
        #   expect(shop_enrollment.errors.any?).to be_truthy
        #   expect(shop_enrollment.errors.full_messages.to_s).to match /You can not keep an existing plan which belongs to previous plan year/
        # end
      end

      context 'when roster create present' do
        let(:employee_created_at) { TimeKeeper.date_of_record }

        it "should allow" do
          expect(shop_enrollment.can_select_coverage?).to be_truthy
        end
      end

      context 'when roster update present' do
        let(:employee_updated_at) { TimeKeeper.date_of_record }

        it "should not allow" do
          expect(shop_enrollment.can_select_coverage?).to be_falsey
        end

        # TODO: code commented out in hbx_enrollment model. code needs to be enabled before adding this spec back.
        # it "should get a error msg" do
        #   shop_enrollment.can_select_coverage?
        #   expect(shop_enrollment.errors.any?).to be_truthy
        #   expect(shop_enrollment.errors.full_messages.to_s).to match /You can not keep an existing plan which belongs to previous plan year/
        # end
      end

      context 'with QLE' do
        let(:effective_on) { qle_date.next_month.beginning_of_month }

        let(:qualifying_life_event_kind) {FactoryBot.create(:qualifying_life_event_kind)}
        let(:user) {instance_double("User", :primary_family => test_family, :person => person)}
        let(:qle) {FactoryBot.create(:qualifying_life_event_kind)}
        let(:test_family) {FactoryBot.build(:family, :with_primary_family_member)}
        let(:person) {shop_family.primary_family_member.person}

        let(:special_enrollment_period) {
          special_enrollment = shop_family.special_enrollment_periods.build({
                                                                                qle_on: qle_date,
                                                                                effective_on_kind: "first_of_month",
                                                                            })
          special_enrollment.qualifying_life_event_kind = qualifying_life_event_kind
          special_enrollment.save
          special_enrollment
        }

        let(:enrollment_kind) { "special_enrollment" }
        let(:special_enrollment_period_id) { special_enrollment_period.id }

        before do
          allow(shop_enrollment).to receive(:plan_year_check).with(employee_role).and_return false
        end

        context 'under special enrollment period' do
          let(:qle_date) { TimeKeeper.date_of_record }

          it "should allow" do
            expect(shop_enrollment.can_select_coverage?).to be_truthy
          end
        end

        context 'outside special enrollment period' do
          let(:qle_date) { TimeKeeper.date_of_record - 2.months }

          it "should not allow" do
            expect(shop_enrollment.can_select_coverage?).to be_falsey
          end
        end
      end
    end
  end

  context "Benefits are terminated" do
    let(:effective_on_date) {TimeKeeper.date_of_record.beginning_of_month}
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile)}

    context "Individual benefit" do
      let(:ivl_family) {FactoryBot.create(:family, :with_primary_family_member)}
      let(:ivl_enrollment) {FactoryBot.create(:hbx_enrollment,
                                               household: ivl_family.latest_household,
                                               coverage_kind: "health",
                                               effective_on: effective_on_date,
                                               enrollment_kind: "open_enrollment",
                                               kind: "individual",
                                               submitted_at: effective_on_date - 10.days,
                                               family: ivl_family
      )
      }
      let(:ivl_termination_date) {TimeKeeper.date_of_record}

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
  end

  describe HbxEnrollment, "given a set of broker accounts", dbclean: :around_each do
    let(:submitted_at) {Time.mktime(2008, 12, 13, 12, 34, 00)}
    subject {HbxEnrollment.new(:submitted_at => submitted_at)}
    let(:broker_agency_account_1) {double(:start_on => start_on_1, :end_on => end_on_1)}
    let(:broker_agency_account_2) {double(:start_on => start_on_2, :end_on => end_on_2)}

    describe "with both accounts active before the purchase, and the second one unterminated", dbclean: :after_each do
      let(:start_on_1) {submitted_at - 12.days}
      let(:start_on_2) {submitted_at - 5.days}
      let(:end_on_1) {nil}
      let(:end_on_2) {nil}

      it "should be able to select the applicable broker" do
        expect(subject.select_applicable_broker_account([broker_agency_account_1, broker_agency_account_2])).to eq broker_agency_account_2
      end
    end

    describe "with both accounts active before the purchase, and the later one terminated", dbclean: :after_each do
      let(:start_on_1) {submitted_at - 12.days}
      let(:start_on_2) {submitted_at - 5.days}
      let(:end_on_1) {nil}
      let(:end_on_2) {submitted_at - 2.days}

      it "should have no applicable broker" do
        expect(subject.select_applicable_broker_account([broker_agency_account_1, broker_agency_account_2])).to eq nil
      end
    end

    describe "with one account active before the purchase, and the other active after", dbclean: :after_each do
      let(:start_on_1) {submitted_at - 12.days}
      let(:start_on_2) {submitted_at + 5.days}
      let(:end_on_1) {nil}
      let(:end_on_2) {nil}

      it "should be able to select the applicable broker" do
        expect(subject.select_applicable_broker_account([broker_agency_account_1, broker_agency_account_2])).to eq broker_agency_account_1
      end
    end

    describe "with one account active before the purchase and terminated before the purchase, and the other active after", dbclean: :after_each do
      let(:start_on_1) {submitted_at - 12.days}
      let(:start_on_2) {submitted_at + 5.days}
      let(:end_on_1) {submitted_at - 3.days}
      let(:end_on_2) {nil}

      it "should have no applicable broker" do
        expect(subject.select_applicable_broker_account([broker_agency_account_1, broker_agency_account_2])).to eq nil
      end
    end
  end

  describe HbxEnrollment, "given an enrollment kind of 'special_enrollment'", dbclean: :around_each do
    subject {HbxEnrollment.new({:enrollment_kind => "special_enrollment"})}

    it "should NOT be a shop new hire" do
      expect(subject.new_hire_enrollment_for_shop?).to eq false
    end

    describe "and given a special enrollment period, with a reason of 'birth'", dbclean: :after_each do
      let(:qle_on) {Date.today}

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

  describe HbxEnrollment, "given an enrollment kind of 'open_enrollment'", dbclean: :around_each do
    subject {HbxEnrollment.new({:enrollment_kind => "open_enrollment"})}

    it "should not have an eligibility event date" do
      expect(subject.eligibility_event_has_date?).to eq false
    end

    describe "in the IVL market", dbclean: :after_each do
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

    describe "in the SHOP market, purchased outside of open enrollment", dbclean: :after_each do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:reference_date) { current_effective_date }
      # let(:open_enrollment_start) {reference_date - 15.days}
      # let(:open_enrollment_end) {reference_date - 5.days}

      let(:purchase_time) {Time.now - 20.days}
      let(:hired_on) {reference_date - 21.days}

      before :each do
        subject.kind = "employer_sponsored"
        subject.submitted_at = purchase_time
        subject.benefit_group_assignment = BenefitGroupAssignment.new({
          :census_employee => CensusEmployee.new({
           :hired_on => hired_on
           })
          })

        allow(subject).to receive(:sponsored_benefit_package).and_return(current_benefit_package)
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

    describe "in the SHOP market, purchased during open enrollment", dbclean: :after_each do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month.prev_month }
      let(:reference_date) { current_effective_date }

      let(:purchase_time) { initial_application.open_enrollment_end_on.prev_day }
      let(:hired_on) {(reference_date - 21.days).to_date}

      before :each do
        subject.kind = "employer_sponsored"
        subject.submitted_at = purchase_time
        subject.benefit_group_assignment = BenefitGroupAssignment.new({
          :census_employee => CensusEmployee.new({
           :hired_on => hired_on,
           :created_at => hired_on
           })
          })

        allow(subject).to receive(:sponsored_benefit_package).and_return(current_benefit_package)
      end

      describe "when coverage start is the same as the plan year", dbclean: :after_each do
        before(:each) do
          subject.effective_on = reference_date
          subject.submitted_at = purchase_time
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

      describe "when coverage start is the different from the plan year", dbclean: :after_each do
        before(:each) do
          subject.effective_on = reference_date + 12.days
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

  describe HbxEnrollment, 'all_enrollments_under_benefit_application', type: :model, dbclean: :around_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let!(:census_employee) { create(:census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, employee_role_id: employee_role.id) }
    let!(:employee_role) { FactoryBot.create(:employee_role, person: person, employer_profile: benefit_sponsorship.profile) }

    let(:person) {FactoryBot.create(:person)}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

    let(:subject) { HbxEnrollment.all_enrollments_under_benefit_application(initial_application) }

    context 'should return coverage_selected enrollment' do
      let(:enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          household: family.active_household,
          aasm_state: "coverage_selected",
          sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
          family: family,
          coverage_kind: "health",
          kind: "employer_sponsored"
        )
      end

      it "should return the enrollment with the benefit group assignment" do
        enrollment
        expect(subject).to include enrollment
      end
    end

    context 'should return waived enrollment' do
      let(:enrollment) do
        FactoryBot.create(
          :hbx_enrollment,
          household: family.active_household,
          aasm_state: "inactive",
          sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
          family: family,
          coverage_kind: "health",
          kind: "employer_sponsored"
        )
      end

      it "should return the enrollment with the benefit group assignment" do
        enrollment
        expect(subject).to include enrollment
      end
    end
  end

  describe HbxEnrollment, 'dental shop calculation related', type: :model, dbclean: :around_each do
    context ".find_enrollments_by_benefit_group_assignment" do

      let(:enrollment) { FactoryBot.create(:hbx_enrollment,
        household: family.active_household,
        benefit_group_assignment_id: benefit_group_assignment.id,
        aasm_state: "coverage_selected",
        family: family,
        coverage_kind: "health",
        kind: "employer_sponsored"
      )}

      let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
      let(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment)}
      let(:subject) { HbxEnrollment.find_enrollments_by_benefit_group_assignment(benefit_group_assignment) }

      it "should return the enrollment with the benefit group assignment" do
        enrollment
        expect(subject).to include enrollment
      end

      it "should be empty if no active coverage" do
        enrollment.update_attributes(aasm_state: "shopping")
        expect(subject).to be_empty
      end

      it "should be empty when no active enrollment with given benefit_group_assignment id" do
        enrollment.update_attributes(aasm_state: "coverage_selected", benefit_group_assignment_id: "")
        expect(subject).to be_empty
      end

      it "should return the dental enrollment" do
        enrollment.update_attributes(coverage_kind: 'dental', aasm_state: 'coverage_selected')
        expect(subject).to include enrollment
      end
    end
  end

  context "A cancelled external enrollment", :dbclean => :after_each do
    let(:family) {FactoryBot.create(:family, :with_primary_family_member)}
    let(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
       household: family.active_household,
       kind: "employer_sponsored",
       submitted_at: TimeKeeper.datetime_of_record - 3.day,
       created_at: TimeKeeper.datetime_of_record - 3.day,
       family: family
       )
    end

    before do
      enrollment.update_attributes(aasm_state:"coverage_canceled")
      enrollment.update_attributes(terminated_on: enrollment.effective_on)
      enrollment.update_attributes(external_enrollment: true)
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
      enrollment.update_attributes!(aasm_state: "coverage_selected")
      enrollment.update_attributes!(external_enrollment: false)
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
    let(:enrollment) {HbxEnrollment.new(kind: 'employer_sponsored')}
    let(:cobra_enrollment) {HbxEnrollment.new(kind: 'employer_sponsored_cobra')}

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
      let(:employee_role) {FactoryBot.create(:employee_role)}
      let(:census_employee) {FactoryBot.create(:census_employee)}
      let(:coverage_termination_date) {TimeKeeper.date_of_record + 1.months}

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
      let(:benefit_group) {FactoryBot.create(:benefit_group)}
      let(:benefit_package) {BenefitPackage.new(title: 'benefit package title')}
      it "for shop" do
        enrollment.kind = 'employer_sponsored'
        enrollment.benefit_group = benefit_group
        expect(enrollment.benefit_package_name).to eq benefit_group.title
      end
    end
  end

  describe HbxEnrollment, 'Updating Existing Coverage', type: :model, dbclean: :around_each do

    include_context "setup benefit market with market catalogs and product packages"

    let(:effective_on) { current_effective_date }
    let(:hired_on) { TimeKeeper.date_of_record - 3.months }

    let(:person) {FactoryBot.create(:person)}
    let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}

    let(:aasm_state) { :active }
    let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, employee_role_id: employee_role.id) }
    let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: hired_on, person: person) }
    let(:enrollment_kind) { "open_enrollment" }
    let(:special_enrollment_period_id) { nil }

    let!(:enrollment) { FactoryBot.create(:hbx_enrollment,
      household: shop_family.latest_household,
      coverage_kind: "health",
      effective_on: effective_on,
      enrollment_kind: enrollment_kind,
      family: shop_family,
      kind: "employer_sponsored",
      submitted_at: effective_on - 20.days,
      benefit_sponsorship_id: benefit_sponsorship.id,
      sponsored_benefit_package_id: current_benefit_package.id,
      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
      employee_role_id: employee_role.id,
      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
      special_enrollment_period_id: special_enrollment_period_id,
      product_id: current_benefit_package.sponsored_benefits[0].reference_product.id
      )
    }

    before do
      employee_role.update(census_employee_id: census_employee.id)
    end

    context 'When family has active coverage and makes changes for their coverage' do

      include_context "setup initial benefit application"

      let(:special_enrollment_period) {
        FactoryBot.create(:special_enrollment_period, family: shop_family)
      }
      let(:new_enrollment_eff_on)  { TimeKeeper.date_of_record.next_month.beginning_of_month }

      let(:new_enrollment) { FactoryBot.create(:hbx_enrollment,
                                                household: shop_family.latest_household,
                                                coverage_kind: "health",
                                                effective_on: new_enrollment_eff_on,
                                                enrollment_kind: enrollment_kind,
                                                family: shop_family,
                                                kind: "employer_sponsored",
                                                submitted_at: TimeKeeper.date_of_record,
                                                benefit_sponsorship_id: benefit_sponsorship.id,
                                                sponsored_benefit_package_id: current_benefit_package.id,
                                                sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                                                employee_role_id: employee_role.id,
                                                benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                                special_enrollment_period_id: special_enrollment_period.id,
                                                predecessor_enrollment_id: enrollment.id,
                                                aasm_state: 'shopping'
      )
      }
      let(:terminated_date)  { new_enrollment_eff_on - 1.day }

      it 'should terminate existing coverage' do
        expect(enrollment.coverage_selected?).to be_truthy
        expect(enrollment.terminated_on).to be_nil
        new_enrollment.select_coverage!
        enrollment.reload
        if terminated_date <= TimeKeeper.date_of_record
          expect(enrollment.coverage_terminated?).to be_truthy
        else
          expect(enrollment.coverage_termination_pending?).to be_truthy
        end
        expect(enrollment.terminated_on).to eq(terminated_date)
      end
    end

    context 'When family passively renewed' do
      include_context "setup renewal application"

      let(:predecessor_application_catalog) { true }
      let(:current_effective_date) { (TimeKeeper.date_of_record + 2.months).beginning_of_month - 1.year }
      let(:renewal_state) { :enrollment_open }
      let(:open_enrollment_period)  { TimeKeeper.date_of_record..(effective_period.min - 10.days) }
      let(:current_benefit_package) { renewal_application.predecessor.benefit_packages[0] }

      let(:generate_passive_renewal) {
        renewal_application.benefit_packages[0].update_attributes(title: current_benefit_package.title + "(#{renewal_application.start_on.year})")
        census_employee.update!(created_at: 2.months.ago)
        census_employee.assign_to_benefit_package(benefit_package, renewal_effective_date)
        benefit_package.renew_member_benefit(census_employee)
      }

      let(:enrollment_effective_on) { renewal_effective_date }
      let(:special_enrollment_period_id) { nil }
      let(:passive_renewal) { shop_family.reload.enrollments.where(:aasm_state => 'auto_renewing').first }

      context 'When Actively Renewed', dbclean: :around_each do

        let(:new_enrollment_product_id) { passive_renewal.product_id }

        let(:new_enrollment) { FactoryBot.create(:hbx_enrollment,
          household: shop_family.latest_household,
          coverage_kind: "health",
          family: shop_family,
          effective_on: enrollment_effective_on,
          enrollment_kind: enrollment_kind,
          kind: "employer_sponsored",
          submitted_at: TimeKeeper.date_of_record,
          benefit_sponsorship_id: benefit_sponsorship.id,
          sponsored_benefit_package_id: benefit_package.id,
          sponsored_benefit_id: benefit_package.sponsored_benefits[0].id,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
          predecessor_enrollment_id: passive_renewal.id,
          product_id: new_enrollment_product_id,
          special_enrollment_period_id: special_enrollment_period_id,
          aasm_state: 'shopping'
          )
        }

        before do
          allow(benefit_package).to receive(:is_renewal_benefit_available?).and_return(true)
          generate_passive_renewal
        end

        context 'with same effective date as passive renewal' do

          it 'should cancel their passive renewal' do
            expect(passive_renewal).not_to be_nil

            new_enrollment.select_coverage!
            passive_renewal.reload
            new_enrollment.reload

            expect(passive_renewal.coverage_canceled?).to be_truthy
            expect(new_enrollment.coverage_selected?).to be_truthy
          end
        end

        context 'with effective date later to the passive renewal' do

          let(:enrollment_effective_on) { renewal_effective_date.next_month }

          it 'should terminate the passive renewal' do
            expect(passive_renewal).not_to be_nil

            new_enrollment.select_coverage!
            passive_renewal.reload
            new_enrollment.reload

            expect(new_enrollment.coverage_selected?).to be_truthy
            expect(passive_renewal.coverage_termination_pending?).to be_truthy
            expect(passive_renewal.terminated_on).to eq(new_enrollment.effective_on - 1.day)
          end
        end
      end

      context '.update_renewal_coverage', dbclean: :around_each do

        before do
          allow(benefit_package).to receive(:is_renewal_benefit_available?).and_return(true)
          generate_passive_renewal
        end

        context 'when EE enters SEP and picks new plan' do
          let(:enrollment_effective_on) { renewal_effective_date - 3.months }

          let(:new_enrollment) { FactoryBot.create(:hbx_enrollment,
            household: shop_family.latest_household,
            coverage_kind: "health",
            family: shop_family,
            effective_on: enrollment_effective_on,
            enrollment_kind: enrollment_kind,
            kind: "employer_sponsored",
            submitted_at: TimeKeeper.date_of_record,
            benefit_sponsorship_id: benefit_sponsorship.id,
            sponsored_benefit_package_id: current_benefit_package.id,
            sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
            employee_role_id: employee_role.id,
            benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
            predecessor_enrollment_id: enrollment.id,
            product_id: new_enrollment_product.id,
            special_enrollment_period_id: special_enrollment_period_id,
            aasm_state: 'shopping'
            )
          }

          let(:new_enrollment_product) {
            product_package = current_benefit_package.sponsored_benefits[0].product_package
            product_package.products.detect{|product| product != enrollment.product }
          }

          let(:special_enrollment_period_id) { FactoryBot.create(:special_enrollment_period, family: shop_family).id }

          it 'should cancel passive renewal and create new passive' do
            expect(passive_renewal).not_to be_nil
            new_enrollment.select_coverage!
            passive_renewal.reload
            new_enrollment.reload
            enrollment.reload
            expect(enrollment.coverage_terminated?).to be_truthy
            expect(passive_renewal.coverage_canceled?).to be_truthy
            expect(new_enrollment.coverage_selected?).to be_truthy
            new_passive = shop_family.reload.active_household.hbx_enrollments.where(:aasm_state => :auto_renewing, :effective_on => renewal_effective_date).first
            expect(new_passive.product).to eq new_enrollment_product.renewal_product
          end

          context 'when employee actively renewed coverage' do

            it 'should not cancel active renewal and should not generate passive' do
              passive_renewal.update(aasm_state: 'coverage_selected')
              new_enrollment.select_coverage!
              passive_renewal.reload
              enrollment.reload
              expect(enrollment.coverage_terminated?).to be_truthy
              expect(new_enrollment.coverage_selected?).to be_truthy
              expect(passive_renewal.coverage_canceled?).to be_falsey
              new_passive = shop_family.reload.enrollments.by_coverage_kind('health').where(:aasm_state => 'auto_renewing').first
              expect(new_passive.blank?).to be_truthy
            end
          end
        end

        context 'when EE terminates current coverage' do

          let(:new_enrollment) { FactoryBot.create(:hbx_enrollment,
            household: shop_family.latest_household,
            family: shop_family,
            coverage_kind: "health",
            effective_on: enrollment_effective_on,
            enrollment_kind: enrollment_kind,
            kind: "employer_sponsored",
            submitted_at: TimeKeeper.date_of_record,
            benefit_sponsorship_id: benefit_sponsorship.id,
            sponsored_benefit_package_id: current_benefit_package.id,
            sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
            employee_role_id: employee_role.id,
            benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
            predecessor_enrollment_id: enrollment.id,
            product_id: enrollment.product_id,
            aasm_state: 'shopping'
            )
          }

          it 'should cancel passive renewal and generate a waiver' do
            expect(passive_renewal).not_to be_nil
            enrollment.terminate_enrollment(TimeKeeper.date_of_record.last_month.end_of_month, 'Because')
            passive_renewal.reload
            enrollment.reload
            expect(enrollment.coverage_terminated?).to be_truthy
            expect(passive_renewal.coverage_canceled?).to be_truthy
            waiver = shop_family.reload.enrollments.where(:aasm_state => 'inactive').first
            expect(waiver.present?).to be_truthy
          end

          it 'should cancel passive renewal and should not generate a duplicate waiver' do
            expect(passive_renewal).not_to be_nil
            new_enrollment.waive_coverage!
            new_enrollment.schedule_coverage_termination!
            passive_renewal.reload
            enrollment.reload
            new_enrollment.reload
            expect(new_enrollment.inactive?).to be_truthy
            expect(passive_renewal.coverage_canceled?).to be_truthy
            passive_waiver = shop_family.reload.enrollments.where(:aasm_state => 'renewing_waived').first
            expect(passive_waiver.present?).to be_falsey
          end
        end
      end

      context '.renewal_enrollments', dbclean: :around_each do
        let(:new_enrollment_product_id) { passive_renewal.product_id }
        let(:new_enrollment) do
          FactoryBot.create(:hbx_enrollment,
            household: shop_family.latest_household,
            coverage_kind: "health",
            family: shop_family,
            effective_on: enrollment_effective_on,
            enrollment_kind: enrollment_kind,
            kind: "employer_sponsored",
            submitted_at: TimeKeeper.date_of_record,
            benefit_sponsorship_id: benefit_sponsorship.id,
            sponsored_benefit_package_id: benefit_package.id,
            sponsored_benefit_id: benefit_package.sponsored_benefits[0].id,
            employee_role_id: employee_role.id,
            benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
            predecessor_enrollment_id: passive_renewal.id,
            product_id: new_enrollment_product_id,
            special_enrollment_period_id: special_enrollment_period_id,
            aasm_state: 'shopping'
          )
        end

        before do
          allow(benefit_package).to receive(:is_renewal_benefit_available?).and_return(true)
          generate_passive_renewal
        end

        it 'should return enrollments by family' do
          enrollments = new_enrollment.renewal_enrollments(renewal_application)

          expect(enrollments).to include(passive_renewal)
        end
      end
    end

    context '.term_existing_shop_enrollments' do
      include_context "setup renewal application"

      let(:predecessor_application_catalog) { true }
      let(:current_effective_date) { (TimeKeeper.date_of_record + 2.months).beginning_of_month - 1.year }
      let(:renewal_state) { :enrollment_open }
      let(:open_enrollment_period)  { TimeKeeper.date_of_record..(effective_period.min - 10.days) }
      let(:current_benefit_package) { renewal_application.predecessor.benefit_packages[0] }
      let(:renewal_benefit_package) { renewal_application.benefit_packages[0] }

      let(:generate_passive_waiver) do
        enrollment.update_attributes(aasm_state: 'inactive')
        renewal_application.benefit_packages[0].update_attributes(title: current_benefit_package.title + "(#{renewal_application.start_on.year})")
        census_employee.update!(created_at: 2.months.ago)
        census_employee.assign_to_benefit_package(benefit_package, renewal_effective_date)
        benefit_package.renew_member_benefit(census_employee)
      end

      let(:generate_passive_renewal) do
        enrollment.update_attributes(aasm_state: 'coverage_enrolled')
        renewal_application.benefit_packages[0].update_attributes(title: current_benefit_package.title + "(#{renewal_application.start_on.year})")
        census_employee.update!(created_at: 2.months.ago)
        census_employee.assign_to_benefit_package(benefit_package, renewal_effective_date)
        benefit_package.renew_member_benefit(census_employee)
      end

      let(:enrollment_effective_on) { renewal_effective_date }
      let(:special_enrollment_period_id) { nil }
      let(:passive_renewal_waived)  { shop_family.reload.enrollments.renewing_waived.first }
      let(:auto_renewal_enrollment) { shop_family.reload.enrollments.auto_renewing.first }
      let(:new_waiver_under_renewal_app) do
        FactoryBot.build(
          :hbx_enrollment,
          kind: 'employer_sponsored',
          coverage_kind: passive_renewal_waived.coverage_kind,
          household: shop_family.active_household,
          benefit_sponsorship_id: benefit_sponsorship.id,
          aasm_state: "shopping",
          predecessor_enrollment_id: passive_renewal_waived.id,
          sponsored_benefit_package_id: renewal_benefit_package.id,
          sponsored_benefit_id: renewal_benefit_package.sponsored_benefits[0].id,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
          family: shop_family
        )
      end

      let(:auto_renewing_under_renewal_app) do
        FactoryBot.build(
          :hbx_enrollment,
          kind: 'employer_sponsored',
          coverage_kind: auto_renewal_enrollment.coverage_kind,
          household: shop_family.active_household,
          benefit_sponsorship_id: benefit_sponsorship.id,
          aasm_state: "shopping",
          predecessor_enrollment_id: auto_renewal_enrollment.id,
          sponsored_benefit_package_id: renewal_benefit_package.id,
          sponsored_benefit_id: renewal_benefit_package.sponsored_benefits[0].id,
          effective_on: renewal_benefit_package.start_on,
          employee_role_id: employee_role.id,
          benefit_group_assignment_id: census_employee.renewal_benefit_group_assignment.id,
          family: shop_family
        )
      end

      before do
        allow(benefit_package).to receive(:is_renewal_benefit_available?).and_return(true)
      end

      it 'should cancel future effective waivers upon creating a new waiver' do
        generate_passive_waiver
        new_waiver_under_renewal_app.waive_enrollment
        expect(passive_renewal_waived.reload.coverage_canceled?).to be_truthy
      end

      it 'should terminate previous active enrollment when waiving passive renewal in open enrollment' do
        generate_passive_renewal
        auto_renewal_enrollment.update_attributes(predecessor_enrollment_id: enrollment.id)
        expect(auto_renewal_enrollment.aasm_state).to eq "auto_renewing"
        auto_renewing_under_renewal_app.waive_enrollment
        expect(enrollment.reload.coverage_termination_pending?).to be_truthy
        expect(enrollment.terminated_on).to eq((enrollment.effective_on + 1.year) - 1.day)
      end

      it 'should terminate previous active enrollment when waiving renewal coverage selected enrollment in open enrollment' do
        generate_passive_renewal
        auto_renewal_enrollment.update_attributes(predecessor_enrollment_id: enrollment.id, aasm_state: 'coverage_selected')
        auto_renewing_under_renewal_app.waive_enrollment
        expect(enrollment.reload.coverage_termination_pending?).to be_truthy
        expect(enrollment.terminated_on).to eq((enrollment.effective_on + 1.year) - 1.day)
      end
    end

    context "market_name" do
      include_context "setup initial benefit application"

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

  describe HbxEnrollment, 'Voiding enrollments', type: :model, dbclean: :around_each do
    let!(:hbx_profile) {FactoryBot.create(:hbx_profile)}
    let(:family) {FactoryBot.build(:individual_market_family)}
    let(:hbx_enrollment) {FactoryBot.build(:hbx_enrollment, :individual_unassisted, family: family, household: family.active_household, effective_on: TimeKeeper.date_of_record)}

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

  describe HbxEnrollment, 'Renewal Purchase', type: :model, dbclean: :around_each do
    let(:family) {FactoryBot.build(:individual_market_family)}
    let(:hbx_enrollment) {FactoryBot.build(:hbx_enrollment, :individual_unassisted, family: family, household: family.active_household, kind: 'individual')}

    context "open enrollment" do
      before do
        hbx_enrollment.update(enrollment_kind: 'open_enrollment')
      end

      it "should return true when auto_renewing" do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, household: family.active_household, aasm_state: 'auto_renewing')
        expect(hbx_enrollment.is_active_renewal_purchase?).to be_truthy
      end

      it "should return true when renewing_coverage_selected" do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, household: family.active_household, aasm_state: 'renewing_coverage_selected')
        expect(hbx_enrollment.is_active_renewal_purchase?).to be_truthy
      end

      it "should return false when coverage_selected" do
        FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, household: family.active_household, aasm_state: 'coverage_selected')
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

  describe HbxEnrollment, 'state machine', dbclean: :around_each do
    let(:family) {FactoryBot.build(:individual_market_family)}
    let(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01')}
    subject {FactoryBot.build(:hbx_enrollment, :individual_unassisted, household: family.active_household, product: product, family: family)}

    shared_examples_for "state machine transitions" do |current_state, new_state, event|
      it "transition #{current_state} to #{new_state} on #{event} event" do
        expect(subject).to transition_from(current_state).to(new_state).on_event(event)
      end
    end

    context "move_to_enrolled event" do
      it_behaves_like "state machine transitions", :unverified, :coverage_selected, :move_to_enrolled
    end

    context "move_to_pending event" do
      it_behaves_like "state machine transitions", :shopping, :unverified, :move_to_pending!
      it_behaves_like "state machine transitions", :coverage_selected, :unverified, :move_to_pending!
      it_behaves_like "state machine transitions", :coverage_enrolled, :unverified, :move_to_pending!
      it_behaves_like "state machine transitions", :auto_renewing, :unverified, :move_to_pending!
    end
  end

  describe HbxEnrollment, 'validate_for_cobra_eligiblity', dbclean: :around_each do

    context 'When employee is designated as cobra' do

      let(:effective_on) {TimeKeeper.date_of_record.beginning_of_month}
      let(:cobra_begin_date) {TimeKeeper.date_of_record.next_month.beginning_of_month}
      let(:hbx_enrollment) {HbxEnrollment.new(kind: 'employer_sponsored', effective_on: effective_on)}
      let(:employee_role) {double(is_cobra_status?: true, census_employee: census_employee)}
      let(:census_employee) {double(cobra_begin_date: cobra_begin_date, have_valid_date_for_cobra?: true, coverage_terminated_on: cobra_begin_date - 1.day)}
      let(:current_user) { FactoryBot.create :user }

      before do
        allow(hbx_enrollment).to receive(:employee_role).and_return(employee_role)
      end

      context 'When Enrollment Effectve date is prior to cobra begin date' do
        it 'should reset enrollment effective date to cobra begin date' do
          hbx_enrollment.validate_for_cobra_eligiblity(employee_role, current_user)
          expect(hbx_enrollment.kind).to eq 'employer_sponsored_cobra'
          expect(hbx_enrollment.effective_on).to eq cobra_begin_date
        end
      end

      context 'When Enrollment Effectve date is after cobra begin date' do
        let(:cobra_begin_date) {TimeKeeper.date_of_record.prev_month.beginning_of_month}

        it 'should not update enrollment effective date' do
          hbx_enrollment.validate_for_cobra_eligiblity(employee_role, current_user)
          expect(hbx_enrollment.kind).to eq 'employer_sponsored_cobra'
          expect(hbx_enrollment.effective_on).to eq effective_on
        end
      end

      context 'When employee not elgibile for cobra' do
        let(:census_employee) {double(cobra_begin_date: cobra_begin_date, have_valid_date_for_cobra?: false, coverage_terminated_on: cobra_begin_date - 1.day)}
        let(:current_user) { FactoryBot.create :user }

        it 'should raise error' do
          expect {hbx_enrollment.validate_for_cobra_eligiblity(employee_role, current_user)}.to raise_error("You may not enroll for cobra after #{Settings.aca.shop_market.cobra_enrollment_period.months} months later of coverage terminated.")
        end
      end
    end
  end

  describe HbxEnrollment, '.build_plan_premium', type: :model, dbclean: :around_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let!(:employer_profile) {benefit_sponsorship.profile}
    let(:benefit_group) {employer_profile.published_plan_year.benefit_groups.first}

    let!(:census_employees) {
      FactoryBot.create :census_employee, :owner, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship
      employee = FactoryBot.create :census_employee, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship
      employee.add_benefit_group_assignment benefit_group, benefit_group.start_on
    }

    let!(:plan) {
      FactoryBot.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: benefit_group.start_on.year, hios_id: "11111111122302-01", csr_variant_id: "01")
    }

    let(:ce) {employer_profile.census_employees.non_business_owner.first}

    let!(:family) {
      person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
      employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, benefit_sponsors_employer_profile_id: employer_profile.id)
      ce.update_attributes({employee_role: employee_role})
      Family.find_or_build_from_employee_role(employee_role)
    }

    let(:person) {family.primary_applicant.person}

    context 'Employer Sponsored Coverage' do
      let!(:enrollment) {
        FactoryBot.create(:hbx_enrollment,
         household: family.active_household,
         family: family,
         coverage_kind: "health",
         effective_on: benefit_group.start_on,
         enrollment_kind: "open_enrollment",
         kind: "employer_sponsored",
         sponsored_benefit_package_id: benefit_group.id,
         employee_role_id: person.active_employee_roles.first.id,
         benefit_group_assignment_id: ce.active_benefit_group_assignment.id,
         plan_id: plan.id
         )
      }

      context 'for congression employer' do
        before do
          allow(enrollment).to receive_message_chain("benefit_group.is_congress") {true}
        end

        it "should build premiums" do
          plan = enrollment.build_plan_premium(qhp_plan: enrollment.plan)
          expect(plan).to be_kind_of(PlanCostDecoratorCongress)
        end
      end

      context 'for non congression employer' do
        before do
          allow(enrollment).to receive_message_chain("benefit_group.is_congress") {false}
          allow(enrollment).to receive(:composite_rated?).and_return(false)
          allow(enrollment).to receive_message_chain("benefit_group.reference_plan") { plan }
        end

        it "should build premiums" do
          plan = enrollment.build_plan_premium(qhp_plan: enrollment.plan)
          expect(plan).to be_kind_of(PlanCostDecorator)
        end
      end
    end

    context 'Individual Coverage' do
      let!(:enrollment) {
        FactoryBot.create(:hbx_enrollment,
         household: family.active_household,
         coverage_kind: "health",
         effective_on: TimeKeeper.date_of_record.beginning_of_month,
         enrollment_kind: "open_enrollment",
         kind: "individual",
         family: family,
         plan_id: plan.id
         )
      }

      it "should build premiums" do
        plan = enrollment.build_plan_premium(qhp_plan: plan)
        expect(plan).to be_kind_of(UnassistedPlanCostDecorator)
      end
    end
  end

  describe HbxEnrollment, dbclean: :around_each do
    include_context "BradyWorkAfterAll"

    before :all do
      create_brady_census_families
    end

    context "Cancel / Terminate Previous Enrollments for Shop" do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
      let(:existing_shop_enrollment) {FactoryBot.create(:hbx_enrollment, :shop, household: family.active_household, effective_on: TimeKeeper.date_of_record, family: family)}
      let(:new_enrollment) {FactoryBot.create(:hbx_enrollment, :shop, household: family.active_household, family: family, predecessor_enrollment_id: existing_shop_enrollment.id, effective_on: TimeKeeper.date_of_record)}

      it "should cancel the previous enrollment if the effective_on date of the previous and the current are the same." do
        new_enrollment.update_existing_shop_coverage
        existing_shop_enrollment.reload
        expect(existing_shop_enrollment.aasm_state).to eq "coverage_canceled"
      end
    end

    context "should not cancel/terminate if Enrollments are from different employers" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:family) { FactoryBot.create(:family, :with_primary_family_member)}
      let(:existing_shop_enrollment) {FactoryBot.create(:hbx_enrollment, :shop, household: family.active_household, aasm_state: 'coverage_enrolled', effective_on: TimeKeeper.date_of_record, family: family, benefit_sponsorship_id: mikes_benefit_sponsorship.id)}
      let(:new_enrollment) {FactoryBot.create(:hbx_enrollment, :shop, household: family.active_household, family: family, predecessor_enrollment_id: existing_shop_enrollment.id, effective_on: TimeKeeper.date_of_record, benefit_sponsorship_id: benefit_sponsorship.id)}

      it 'should cancel the previous enrollment if the effective_on date of the previous and the current are the same.' do
        new_enrollment.update_existing_shop_coverage
        expect(existing_shop_enrollment.reload.aasm_state).to eq 'coverage_enrolled'
      end
    end

    context "Cancel / Terminate Previous Enrollments for IVL" do
      attr_reader :enrollment, :household, :coverage_household

      let(:consumer_role) {FactoryBot.create(:consumer_role)}
      let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
      let(:benefit_package) {hbx_profile.benefit_sponsorship.benefit_coverage_periods.first.benefit_packages.first}
      let(:benefit_coverage_period) {hbx_profile.benefit_sponsorship.benefit_coverage_periods.first}
      let(:family) {mikes_family}
      let(:existing_ivl_enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month, family: family, benefit_package_id: benefit_package.id)}
      let(:new_ivl_enrollment) {FactoryBot.create(:hbx_enrollment, :individual_unassisted, household: family.active_household, effective_on: TimeKeeper.date_of_record.beginning_of_month, family: family, benefit_package_id: benefit_package.id)}


      before :each do
        @household = mikes_family.households.first
        @coverage_household = household.coverage_households.first
        allow(benefit_coverage_period).to receive(:earliest_effective_date).and_return TimeKeeper.date_of_record
        allow(coverage_household).to receive(:household).and_return household
        allow(household).to receive(:family).and_return family
        allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
        existing_ivl_enrollment.update_attributes(aasm_state: "coverage_selected", enrollment_signature: "somerandomthing!",effective_on: TimeKeeper.date_of_record.beginning_of_month)
        new_ivl_enrollment.update_attributes(enrollment_signature: "somerandomthing!", effective_on: TimeKeeper.date_of_record.beginning_of_month)
      end

      it "should cancel the previous enrollment if the effective_on date of the previous and the current are the same." do
        new_ivl_enrollment.cancel_previous(TimeKeeper.date_of_record.year)
        existing_ivl_enrollment.reload
        expect(existing_ivl_enrollment.aasm_state).to eq "coverage_canceled"
      end
    end
  end
end


describe HbxEnrollment, type: :model, :dbclean => :around_each do
  let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }

  include_context "setup benefit market with market catalogs and product packages" do
    let(:product_kinds)  { [:health, :dental] }
  end

  include_context "setup initial benefit application" do
    let(:dental_sponsored_benefit) { true }
  end

  describe ".renew_benefit", :dbclean => :after_each do
    describe "given an renewing employer just entered open enrollment", dbclean: :after_each do
      describe "with employees who have made the following plan selections previous year:
        - employee A has purchased:
          - One health enrollment (Enrollment 1)
          - One dental enrollment (Enrollment 2)
        - employee B has purchased:
          - One health enrollment (Enrollment 3)
          - One dental waiver (Enrollment 4)
        - employee C has purchased:
          - One health waiver (Enrollment 5)
          - One dental enrollment (Enrollment 6)
        - employee D has purchased:
          - One health waiver (Enrollment 7)
          - One dental waiver (Enrollment 8)
        - employee E has none
      ", dbclean: :after_each do


        let(:census_employees) {
          create_list(:census_employee, 5, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
        }

        let(:employee_A) {
          ce = census_employees[0]
          create_person(ce, abc_profile)
        }

        let!(:enrollment_1) {
          create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
            submitted_at: current_effective_date - 10.days)
        }

        let!(:enrollment_2) {
          create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental')
        }

        let(:employee_B) {
          ce = census_employees[1]
          create_person(ce, abc_profile)
        }

        let!(:enrollment_3) {
          create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B,
            submitted_at: current_effective_date - 10.days)
        }

        let!(:enrollment_4) {
          create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B,
            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental', status: 'inactive')
        }

        let(:employee_C) {
          ce = census_employees[2]
          create_person(ce, abc_profile)
        }

        let!(:enrollment_5) {
          create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C,
            submitted_at: current_effective_date - 10.days, status: 'inactive')
        }

        let!(:enrollment_6) {
          create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C,
            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental')
        }

        let(:employee_D) {
          ce = census_employees[3]
          create_person(ce, abc_profile)
        }

        let!(:enrollment_7) {
          create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.active_benefit_group_assignment, employee_role: employee_D,
            submitted_at: current_effective_date - 10.days, status: 'inactive')
        }

        let!(:enrollment_8) {
          create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.active_benefit_group_assignment, employee_role: employee_D,
            submitted_at: current_effective_date - 10.days, coverage_kind: 'dental', status: 'inactive')
        }

        let!(:employee_E) {
          ce = census_employees[3]
          create_person(ce, abc_profile)
        }

        let(:renewal_application) {
          renewal_effective_date = current_effective_date.next_year
          service_areas = initial_application.benefit_sponsorship.service_areas_on(renewal_effective_date)
          benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(service_areas, renewal_effective_date)
          r_application = initial_application.renew(benefit_sponsor_catalog)
          r_application.save
          r_application
        }

        let(:initial_benefit_package) { initial_application.benefit_packages[0] }

        let(:renewal_benefit_package) {
          renewal_application.benefit_packages[0]
        }

        before do
          allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(100.0)
          renewal_benefit_package.update_attributes(title: initial_benefit_package.title + "(#{renewal_application.effective_period.min.year})")
          renewal_benefit_package.sponsored_benefits.each do |sponsored_benefit|
            allow(sponsored_benefit).to receive(:products).and_return(sponsored_benefit.product_package.products)
          end
          renewal_application
        end

        context 'renewing employee A' do

          before(:each) do
            renewal_benefit_package.renew_member_benefit(census_employees[0])
            family.reload
          end

          let(:family) { employee_A.person.primary_family }
          let(:health_renewals) { family.active_household.hbx_enrollments.renewing.by_health }
          let(:dental_renewals) { family.active_household.hbx_enrollments.renewing.by_dental }

          it 'does renew both health and dental enrollment' do
            expect(health_renewals.size).to eq 1
            expect(health_renewals[0].product).to eq enrollment_1.product.renewal_product
            expect(dental_renewals.size).to eq 1
            expect(dental_renewals[0].product).to eq enrollment_2.product.renewal_product
          end
        end

        context 'renewing employee B' do

          before do
            renewal_benefit_package.renew_member_benefit(census_employees[1])
            family.reload
          end

          let(:family) { employee_B.person.primary_family }
          let(:health_renewals) { family.active_household.hbx_enrollments.renewing.by_health }
          let(:dental_renewals) { family.active_household.hbx_enrollments.by_dental.select{|en| en.renewing_waived?} }

          it 'does renew health coverage and waive dental coverage' do
            expect(health_renewals.size).to eq 1
            expect(health_renewals[0].product).to eq enrollment_3.product.renewal_product
            expect(dental_renewals.size).to eq 1
          end
        end

        context 'renewing employee C' do

          before do
            renewal_benefit_package.renew_member_benefit(census_employees[2])
            family.reload
          end

          let(:family) { employee_C.person.primary_family }
          let(:health_renewals) { family.active_household.hbx_enrollments.by_health.select{|en| en.renewing_waived?} }
          let(:dental_renewals) { family.active_household.hbx_enrollments.renewing.by_dental }

          it 'does renew health coverage and waive dental coverage' do
            expect(health_renewals.size).to eq 1
            expect(dental_renewals.size).to eq 1
            expect(dental_renewals[0].product).to eq enrollment_6.product.renewal_product
          end
        end

        context 'renewing employee D' do

          before do
            renewal_benefit_package.update_attributes(title: initial_benefit_package.title + "(#{renewal_application.effective_period.min.year})")
            renewal_benefit_package.renew_member_benefit(census_employees[3])
            family.reload
          end

          let(:family) { employee_D.person.primary_family }
          let(:passive_renewals) { family.active_household.hbx_enrollments.renewing }
          let(:health_waivers) { family.active_household.hbx_enrollments.by_health.select{|en| en.renewing_waived?} }
          let(:dental_waivers) { family.active_household.hbx_enrollments.by_dental.select{|en| en.renewing_waived?} }

          it 'does renew health coverage and waive dental coverage' do
            expect(passive_renewals).to be_empty
            expect(health_waivers.size).to eq 1
            expect(dental_waivers.size).to eq 1
          end
        end

        context 'renewing employee E' do

          before do
            renewal_benefit_package.renew_member_benefit(census_employees[4])
            family.reload
          end

          let(:family) { employee_E.person.primary_family }
          let(:passive_renewals) { family.active_household.hbx_enrollments.renewing }
          let(:passive_waivers) { family.active_household.hbx_enrollments.select{|en| en.renewing_waived?} }

          it 'does renew health coverage and waive dental coverage' do
            expect(passive_renewals).to be_empty
            expect(passive_waivers).to be_empty
          end
        end

        def create_person(ce, employer_profile)
          person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
          employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
          ce.update_attributes!({employee_role_id: employee_role.id})
          Family.find_or_build_from_employee_role(employee_role)
          employee_role
        end

        def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil, coverage_kind: 'health')
          benefit_package = benefit_group_assignment.benefit_package
          sponsored_benefit = benefit_package.sponsored_benefit_for(coverage_kind.to_sym)
          FactoryBot.create(:hbx_enrollment,:with_enrollment_members,
            enrollment_members: [family.primary_applicant],
            household: family.active_household,
            coverage_kind: coverage_kind,
            effective_on: benefit_package.start_on,
            family: family,
            enrollment_kind: enrollment_kind,
            kind: "employer_sponsored",
            submitted_at: submitted_at,
            employee_role_id: employee_role.id,
            benefit_sponsorship: benefit_package.benefit_sponsorship,
            sponsored_benefit_package: benefit_package,
            sponsored_benefit: sponsored_benefit,
            benefit_group_assignment_id: benefit_group_assignment.id,
            product: sponsored_benefit.reference_product,
            aasm_state: status
            )
        end
      end
    end
  end
end


  describe "#notify_enrollment_cancel_or_termination_event", :dbclean => :after_each do
    let(:family) { FactoryBot.build(:family, :with_primary_family_member_and_dependent)}
    let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment, family: family,household: family.active_household, kind: "employer_sponsored", aasm_state: "coverage_terminated") }
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    it "should notify event" do # loud transaction
      expect(hbx_enrollment).to receive(:notify).with(
        "acapi.info.events.hbx_enrollment.terminated",
        {
          :reply_to => glue_event_queue_name,
          "hbx_enrollment_id" => hbx_enrollment.hbx_id,
          "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
          "is_trading_partner_publishable" => true
        }
      )
      hbx_enrollment.notify_enrollment_cancel_or_termination_event(true)
    end

    it "should notify event, with trading_partner_publishable flag false" do # silent transaction
      expect(hbx_enrollment).to receive(:notify).with(
        "acapi.info.events.hbx_enrollment.terminated",
        {
          :reply_to => glue_event_queue_name,
          "hbx_enrollment_id" => hbx_enrollment.hbx_id,
          "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
          "is_trading_partner_publishable" => false
        }
      )
      hbx_enrollment.notify_enrollment_cancel_or_termination_event(false)
    end
  end
#TODO: fix me when ivl plans refactored to products
# describe HbxEnrollment, dbclean: :after_all do
#   let!(:family100) { FactoryBot.create(:family, :with_primary_family_member) }
#   let!(:enrollment100) { FactoryBot.create(:hbx_enrollment, household: family100.active_household, kind: "individual") }
#   let!(:plan100) { FactoryBot.create(:plan) }
#
#   describe "is_an_existing_plan?" do
#     context "for checking if a new plan is similar to the given enr's plan " do
#       it "should return true as the compared plan has similar hios_id and same active year" do
#         expect(enrollment100.is_an_existing_plan?(enrollment100.plan)).to eq true
#       end
#
#       it "should return false as the compared plan has a different hios_id" do
#         expect(enrollment100.is_an_existing_plan?(plan100)).to eq false
#       end
#     end
#   end
# end


describe HbxEnrollment, dbclean: :after_all do
  let!(:ivl_person)       { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:ivl_family)       { FactoryBot.create(:family, :with_primary_family_member, person: ivl_person) }
  let!(:ivl_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      household: ivl_family.active_household,
      effective_on: TimeKeeper.date_of_record.beginning_of_year,
      family: ivl_family,
      kind: "individual",
      is_any_enrollment_member_outstanding: true,
      aasm_state: "coverage_selected"
    )
  end

  let!(:ivl_enrollment_member)  { FactoryBot.create(:hbx_enrollment_member, is_subscriber: true,
                                  applicant_id: ivl_family.primary_applicant.id, hbx_enrollment: ivl_enrollment,
                                  eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record) }

  context ".is_ivl_actively_outstanding?" do
    it "should return true" do
      ivl_person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
      ivl_enrollment.save!
      expect(ivl_enrollment.is_ivl_actively_outstanding?).to be_truthy
    end

    it "should return false" do
      expect(ivl_enrollment.is_ivl_actively_outstanding?).to be_falsey
    end
  end

  context ".enrollments_for_display" do
    it "should return enrollments for display matching the family id" do
      expect(HbxEnrollment.enrollments_for_display(ivl_family.id).map{|a|a['_id']}).to include (ivl_enrollment.id)
    end
  end

  context "for set_is_any_enrollment_member_outstanding" do
    it "should return true for is_any_enrollment_member_outstanding" do
      ivl_person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
      ivl_enrollment.save!
      expect(ivl_enrollment.is_any_enrollment_member_outstanding).to be_truthy
    end

    it "should return false for is_any_enrollment_member_outstanding" do
      ivl_enrollment.save!
      expect(ivl_enrollment.is_any_enrollment_member_outstanding).to be_falsey
    end
  end
end


describe HbxEnrollment,"reinstate and change end date", type: :model, :dbclean => :around_each do

  context "Terminated enrollment re-instatement" do
    let(:current_date) { Date.new(TimeKeeper.date_of_record.year, 6, 1) }
    let(:effective_on_date)         { Date.new(TimeKeeper.date_of_record.year, 3, 1) }
    let(:terminated_on_date)        {effective_on_date + 10.days}

    before do
      TimeKeeper.set_date_of_record_unprotected!(current_date)
    end

    context "for Individual market" do
      let(:ivl_family)        { FactoryBot.create(:family, :with_primary_family_member) }

      let(:ivl_enrollment)    {
        FactoryBot.create(:hbx_enrollment,
                           family: ivl_family,
                           household: ivl_family.latest_household,
                           coverage_kind: "health",
                           effective_on: effective_on_date,
                           enrollment_kind: "open_enrollment",
                           kind: "individual",
                           aasm_state: "coverage_terminated",
                           terminated_on: terminated_on_date)
      }

      it "should re-instate enrollment" do
        ivl_enrollment.reinstate
        reinstated_enrollment = HbxEnrollment.where(family_id:ivl_family.id).detect{|e| e.coverage_selected?}

        expect(reinstated_enrollment.present?).to be_truthy
        expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
        expect(reinstated_enrollment.effective_on).to eq terminated_on_date.next_day
      end
    end

    context "for SHOP market" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:effective_on) { current_effective_date }
      let(:hired_on) { TimeKeeper.date_of_record - 3.months }
      let(:employee_created_at) { hired_on }
      let(:employee_updated_at) { employee_created_at }

      let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
      let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
      let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
      let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

      let(:aasm_state) { :active }
      let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let!(:shop_enrollment) { FactoryBot.create(:hbx_enrollment,
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
      }

      before do
        census_employee.update_attributes(employee_role_id: employee_role.id)
        census_employee.terminate_employment(effective_on + 1.days)
        shop_enrollment.reload
        census_employee.reload
      end

      it "should have terminated enrollment & cenuss employee" do
        expect(shop_enrollment.coverage_termination_pending?).to be_truthy
        expect(census_employee.employee_termination_pending?).to be_truthy
      end

      context 'when re-instated' do
        before do
          census_employee.terminate_employee_role!
          shop_enrollment.reinstate
        end

        it "should have re-instate enrollment" do
          reinstated_enrollment = HbxEnrollment.where(family_id:shop_family.id).detect{|e| e.coverage_enrolled?}

          expect(reinstated_enrollment.present?).to be_truthy
          expect(reinstated_enrollment.workflow_state_transitions.where(:to_state => 'coverage_reinstated').present?).to be_truthy
          expect(reinstated_enrollment.effective_on).to eq shop_enrollment.terminated_on.next_day
        end

        it 'should re-instate census employee' do
          census_employee.reload
          expect(census_employee.employee_role_linked?).to be_truthy
        end
      end
    end
  end

  ###########

  describe "#is_reinstated_enrollment?" do
    let(:hbx_enrollment) { HbxEnrollment.new(kind: 'employer_sponsored') }
    let(:workflow_state_transition) {FactoryBot.build(:workflow_state_transition,:from_state => "coverage_reinstated", :to_state => "coverage_selected")}
    context 'when enrollment has been reinstated' do
      it "should have reinstated enrollmentt" do
        allow(hbx_enrollment).to receive(:workflow_state_transitions).and_return([workflow_state_transition])
        expect(hbx_enrollment.is_reinstated_enrollment?).to be_truthy
      end
    end
    context 'when enrollment has not been reinstated' do
      it "should have reinstated enrollmentt" do
        allow(hbx_enrollment).to receive(:workflow_state_transitions).and_return([])
        expect(hbx_enrollment.is_reinstated_enrollment?).to be_falsey
      end
    end
  end

  describe "#can_be_reinstated?" do

    context "for Individual market" do
      let(:ivl_family)        { FactoryBot.create(:family, :with_primary_family_member) }

      let(:ivl_enrollment)    {
        FactoryBot.create(:hbx_enrollment,
                           family: ivl_family,
                           household: ivl_family.latest_household,
                           coverage_kind: "health",
                           effective_on: TimeKeeper.date_of_record.last_year.beginning_of_year,
                           enrollment_kind: "open_enrollment",
                           kind: "individual",
                           aasm_state: "coverage_terminated",
                           terminated_on: TimeKeeper.date_of_record.last_year.end_of_year)
      }

      it "enrollment termianted previous year can't be reinstated?" do
        expect(ivl_enrollment.can_be_reinstated?).to be_falsey
      end

      it "enrollment termianted during current year can be reinstated?" do
        ivl_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.beginning_of_year, terminated_on: TimeKeeper.date_of_record.end_of_month)
        ivl_enrollment.reload
        expect(ivl_enrollment.can_be_reinstated?).to be_truthy
      end

    end

    context "for SHOP market" do

      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:effective_on) { current_effective_date }
      let(:hired_on) { TimeKeeper.date_of_record - 3.months }
      let(:employee_created_at) { hired_on }
      let(:employee_updated_at) { employee_created_at }

      let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
      let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
      let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
      let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

      let(:aasm_state) { :active }
      let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let!(:enrollment) { FactoryBot.create(:hbx_enrollment,
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
      }


      context "reinstating coverage_terminated enrollment" do
        context 'reinstated effective date falls outside active plan year' do
          before do
            enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on)
            enrollment.reload
          end

          it "should return false" do
            expect(enrollment.can_be_reinstated?).to be_falsey
          end
        end

        context 'reinstated effective date falls with in range of active plan year' do
          before do
            enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
            enrollment.reload
          end

          it "should return true" do
            expect(enrollment.can_be_reinstated?).to be_truthy
          end
        end
      end

      context "reinstating coverage_terminated pending enrollment" do
        context 'reinstated effective date falls outside active plan year' do
          before do
            enrollment.update_attributes(aasm_state: 'coverage_termination_pending', terminated_on: current_benefit_package.benefit_application.end_on)
            enrollment.reload
          end

          it "should return false" do
            expect(enrollment.can_be_reinstated?).to be_falsey
          end
        end

        context 'reinstated effective date falls with in range of active plan year' do
          before do
            enrollment.update_attributes(aasm_state: 'coverage_termination_pending', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
            enrollment.reload
          end

          it "should return true" do
            expect(enrollment.can_be_reinstated?).to be_truthy
          end
        end
      end

      context 'for reinstated enrollment no active coverage offering by employer' do

        before do
          current_benefit_package.benefit_application.update_attributes(aasm_state: :terminated)
          enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
          enrollment.reload
        end

        it "should return true" do
          expect(enrollment.can_be_reinstated?).to be_falsey
        end
      end

      context "reinstating employer sponsored enrollment for cobra employee" do

        before do
          enrollment.update_attributes(aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
          enrollment.employee_role.census_employee.update_attributes(aasm_state:'cobra_linked', cobra_begin_date: TimeKeeper.date_of_record)
        end

        it "should return false" do
          expect(enrollment.can_be_reinstated?).to be_falsey
        end
      end

      context "reinstating cobra enrollment for active employee" do

        before do
          enrollment.update_attributes(kind:'employer_sponsored_cobra', aasm_state: 'coverage_terminated', terminated_on: current_benefit_package.benefit_application.end_on - 1.month)
        end

        it "should return false" do
          expect(enrollment.can_be_reinstated?).to be_falsey
        end

      end
    end
  end

  describe "#has_active_or_term_exists_for_reinstated_date?" do

    context "for Individual market" do
      let(:ivl_family)        { FactoryBot.create(:family, :with_primary_family_member) }

      let(:ivl_enrollment)    {
        FactoryBot.create(:hbx_enrollment,
                           family: ivl_family,
                           household: ivl_family.latest_household,
                           coverage_kind: "health",
                           effective_on: TimeKeeper.date_of_record.last_year.beginning_of_month,
                           enrollment_kind: "open_enrollment",
                           kind: "individual",
                           aasm_state: "coverage_terminated",
                           terminated_on: TimeKeeper.date_of_record.end_of_month)
      }

      let!(:ivl_enrollment2)    {
        FactoryBot.create(:hbx_enrollment,
                           family: ivl_family,
                           household: ivl_family.latest_household,
                           coverage_kind: "health",
                           enrollment_kind: "open_enrollment",
                           kind: "individual",
                           aasm_state: "coverage_selected",
                           effective_on: TimeKeeper.date_of_record.end_of_month + 1.day)
      }


      it "should return true if active enrollment exists for reinstated date " do
        expect(ivl_enrollment.has_active_or_term_exists_for_reinstated_date?).to be_truthy
      end

      it "should return true if termianted enrollment exists for reinstated date" do
        ivl_enrollment2.update_attributes(effective_on: TimeKeeper.date_of_record.end_of_month + 1.day, aasm_state: "coverage_terminated",)
        ivl_enrollment2.reload
        expect(ivl_enrollment.has_active_or_term_exists_for_reinstated_date?).to be_truthy
      end

      it "should return true if future active enrollment exists" do
        ivl_enrollment2.update_attributes(aasm_state: "coverage_selected", effective_on: TimeKeeper.date_of_record.beginning_of_month + 1.months)
        ivl_enrollment2.reload
        expect(ivl_enrollment.has_active_or_term_exists_for_reinstated_date?).to be_truthy
      end

      it "should return false if no active enrollment exists for reinstated date" do
        ivl_enrollment2.update_attributes(effective_on: TimeKeeper.date_of_record.end_of_month + 1.day, aasm_state: "coverage_canceled",)
        ivl_enrollment2.reload
        expect(ivl_enrollment.has_active_or_term_exists_for_reinstated_date?).to be_falsey
      end

    end

    context "for SHOP market" do
      include_context "setup benefit market with market catalogs and product packages"
      include_context "setup initial benefit application"

      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:effective_on) { current_effective_date }
      let(:hired_on) { TimeKeeper.date_of_record - 3.months }
      let(:employee_created_at) { hired_on }
      let(:employee_updated_at) { employee_created_at }

      let(:person) {FactoryBot.create(:person, first_name: 'John', last_name: 'Smith', dob: '1966-10-10'.to_date, ssn: '123456789')}
      let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
      let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
      let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

      let(:aasm_state) { :active }
      let(:census_employee) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
      let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
      let(:enrollment_kind) { "open_enrollment" }
      let(:special_enrollment_period_id) { nil }
      let!(:enrollment) { FactoryBot.create(:hbx_enrollment,
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
                                            aasm_state: "coverage_terminated",
                                            benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                                            terminated_on: effective_on.end_of_month)
      }
      let!(:enrollment2) { FactoryBot.create(:hbx_enrollment,
                                            household: shop_family.latest_household,
                                            coverage_kind: "health",
                                            family: shop_family,
                                            effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                                            enrollment_kind: enrollment_kind,
                                            kind: "employer_sponsored",
                                            benefit_sponsorship_id: benefit_sponsorship.id,
                                            sponsored_benefit_package_id: current_benefit_package.id,
                                            sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                                            employee_role_id: employee_role.id,
                                            product: sponsored_benefit.reference_product,
                                             aasm_state: "coverage_selected",
                                            benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)

      }

      it "should return true if active enrollment exists for reinstated date " do
        expect(enrollment.has_active_or_term_exists_for_reinstated_date?).to be_truthy
      end

      it "should return true if termianted enrollment exists for reinstated date" do
        enrollment2.update_attributes(effective_on:effective_on.end_of_month + 1.day, aasm_state: "coverage_terminated")
        enrollment2.reload
        expect(enrollment.has_active_or_term_exists_for_reinstated_date?).to be_truthy
      end

      it "should return true if future active enrollment exists" do
        enrollment2.update_attributes(effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month + 1.month)
        enrollment2.reload
        expect(enrollment.has_active_or_term_exists_for_reinstated_date?).to be_truthy
      end

      it "should return false if no active enrollment exists for reinstated date" do
        enrollment2.update_attributes(effective_on: effective_on.end_of_month + 1.day, aasm_state: "coverage_canceled")
        enrollment2.reload
        expect(enrollment.has_active_or_term_exists_for_reinstated_date?).to be_falsey
      end

      context "with employer_sponsored & active cobra enrollment" do

        it "should return true if active enrollment exists for reinstated date " do
          enrollment2.update_attributes(kind: "employer_sponsored_cobra")
          enrollment2.reload
          expect(enrollment.has_active_or_term_exists_for_reinstated_date?).to be_truthy
        end

        it "should return true if future active enrollment exists" do
          enrollment2.update_attributes(kind: "employer_sponsored_cobra", effective_on: effective_on.end_of_month + 1.day)
          enrollment2.reload
          expect(enrollment.has_active_or_term_exists_for_reinstated_date?).to be_truthy
        end

        it "should return false if no active enrollment exists for reinstated date" do
          enrollment2.update_attributes(kind: "employer_sponsored_cobra", effective_on: effective_on.end_of_month + 1.day, aasm_state: "coverage_canceled")
          enrollment2.reload
          expect(enrollment.has_active_or_term_exists_for_reinstated_date?).to be_falsey
        end
      end

      context "enrollment from two mutiple employers." do

        include_context "setup benefit market with market catalogs and product packages"
        include_context "setup initial benefit application"

        let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
        let(:effective_on) { current_effective_date }
        let(:hired_on) { TimeKeeper.date_of_record - 3.months }
        let(:employee_created_at) { hired_on }
        let(:employee_updated_at) { employee_created_at }

        let!(:sponsored_benefit2) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
        let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

        let(:aasm_state) { :active }
        let(:census_employee2) { create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at) }
        let(:employee_role2) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee2.hired_on, census_employee_id: census_employee2.id) }
        let(:enrollment_kind) { "open_enrollment" }
        let(:special_enrollment_period_id) { nil }

        let!(:enrollment3) { FactoryBot.create(:hbx_enrollment,
                                               household: shop_family.latest_household,
                                               coverage_kind: "health",
                                               family: shop_family,
                                               effective_on: effective_on.end_of_month,
                                               enrollment_kind: enrollment_kind,
                                               kind: "employer_sponsored",
                                               benefit_sponsorship_id: benefit_sponsorship.id,
                                               sponsored_benefit_package_id: current_benefit_package.id,
                                               sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                                               employee_role_id: employee_role2.id,
                                               product: sponsored_benefit2.reference_product,
                                               aasm_state: "coverage_selected",
                                               benefit_group_assignment_id: census_employee2.active_benefit_group_assignment.id,
                                               terminated_on: effective_on.end_of_month)}


        it "should return false when reinstated date enrollment exits with different employer " do
          expect(enrollment3.has_active_or_term_exists_for_reinstated_date?).to be_falsey
        end
      end
    end
  end

  context '.display_make_changes_for_ivl?' do
    let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }
    let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
    let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
    let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
    let(:sep) {SpecialEnrollmentPeriod.new(effective_on: TimeKeeper.date_of_record, start_on: TimeKeeper.date_of_record, end_on: TimeKeeper.date_of_record + 1)}
    let!(:enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        aasm_state: 'coverage_selected')
    end

    before :each do
      allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
      allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
      allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    end

    context 'for shop' do

      before do
        enrollment.kind = 'employer_sponsored'
        enrollment.save
      end

      it 'should return true' do
        expect(enrollment.display_make_changes_for_ivl?).to be_truthy
      end
    end

    context 'for ivl' do

      before do
        enrollment.kind = 'individual'
        enrollment.save
      end

      context 'family with active sep' do
        before do
          allow(family).to receive(:latest_ivl_sep).and_return sep
        end

        it 'should return true' do
          expect(enrollment.display_make_changes_for_ivl?).to be_truthy
        end
      end

      context 'under open enrollment period' do

        before do
          allow(family).to receive(:is_under_ivl_open_enrollment?).and_return true
        end

        it 'should return true' do
          expect(enrollment.display_make_changes_for_ivl?).to be_truthy
        end
      end
    end
  end


  describe "#reterm_enrollment_with_earlier_date" do
    let(:user) { FactoryBot.create(:user, roles: ["hbx_staff"]) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }
    let(:original_termination_date) { TimeKeeper.date_of_record.next_month.end_of_month }
    let!(:enrollment) {
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        household: family.active_household,
                        coverage_kind: "health",
                        kind: 'employer_sponsored',
                        effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                        terminated_on: original_termination_date,
                        aasm_state: 'coverage_termination_pending'
      )}
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    context "shop enrollment" do
      context "enrollment that already terminated with past date" do
        context "with new past or current termination date" do
          let(:terminated_date) { original_termination_date - 1.day }
          let(:original_termination_date) { TimeKeeper.date_of_record.beginning_of_month }

          it "should update enrollment with new end date and notify enrollment" do
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
            enrollment.reterm_enrollment_with_earlier_date(terminated_date, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq "coverage_terminated"
            expect(enrollment.terminated_on).to eq terminated_date
          end
        end

        context "new term date greater than current termination date" do
          it "return false" do
            expect(enrollment.reterm_enrollment_with_earlier_date(TimeKeeper.date_of_record + 2.months, false)).to eq false
          end
        end
      end

      context "enrollment that already terminated with future date" do
        context "with new future termination date" do
          it "should update enrollment with new end date and notify enrollment" do
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
            enrollment.reterm_enrollment_with_earlier_date(TimeKeeper.date_of_record + 1.day, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq "coverage_termination_pending"
            expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record + 1.day
          end
        end
      end
    end

    context "IVL enrollment" do

      before do
        enrollment.kind = "individual"
        enrollment.save
      end

      context "enrollment that already terminated with past date" do
        context "with new past or current termination date" do
          it "should update enrollment with new end date and notify enrollment" do
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
            enrollment.reterm_enrollment_with_earlier_date(TimeKeeper.date_of_record, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq "coverage_terminated"
            expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record
          end
        end
      end

      context "enrollment that already terminated with future date" do
        context "with new future termination date" do
          it "should update enrollment with new end date and notify enrollment" do
            expect(enrollment).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
            enrollment.reterm_enrollment_with_earlier_date(TimeKeeper.date_of_record + 1.day, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq "coverage_terminated"
            expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record + 1.day
          end
        end
      end
    end
  end

  describe '#cancel_terminated_enrollment' do
    let(:user) { FactoryBot.create(:user, roles: ['hbx_staff']) }
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:household) { FactoryBot.create(:household, family: family) }
    let!(:enrollment) {
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                         household: family.active_household,
                         coverage_kind: 'health',
                         kind: 'employer_sponsored',
                         effective_on: TimeKeeper.date_of_record.last_month.beginning_of_month,
                         terminated_on: TimeKeeper.date_of_record.end_of_month,
                         aasm_state: 'coverage_termination_pending'
      )}
    let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

    context 'shop enrollment' do
      context 'enrollment that already terminated with past date' do
        context 'with new termination date == enrollment effective date' do

          before do
            enrollment.update_attributes(aasm_state:'coverage_terminated', terminated_on: TimeKeeper.date_of_record - 1.day)
            enrollment.reload
          end
          it 'should cancel enrollment' do
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated', {:reply_to=>glue_event_queue_name, 'hbx_enrollment_id' => enrollment.hbx_id, 'enrollment_action_uri' => 'urn:openhbx:terms:v1:enrollment#terminate_enrollment', 'is_trading_partner_publishable' => false})
            enrollment.cancel_terminated_enrollment(TimeKeeper.date_of_record.last_month.beginning_of_month, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq 'coverage_canceled'
            expect(enrollment.terminated_on).to eq nil
            expect(enrollment.termination_submitted_on).to eq nil
            expect(enrollment.terminate_reason).to eq nil
          end
        end
      end

      context 'enrollment that already terminated with future date' do
        context 'with new termination date == enrollment effective date' do
          it 'should cancel enrollment' do
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated', {:reply_to=>glue_event_queue_name, 'hbx_enrollment_id' => enrollment.hbx_id, 'enrollment_action_uri' => 'urn:openhbx:terms:v1:enrollment#terminate_enrollment', 'is_trading_partner_publishable' => false})
            enrollment.cancel_terminated_enrollment(TimeKeeper.date_of_record.last_month.beginning_of_month, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq 'coverage_canceled'
            expect(enrollment.terminated_on).to eq nil
            expect(enrollment.termination_submitted_on).to eq nil
            expect(enrollment.terminate_reason).to eq nil
          end
        end
      end
    end

    context 'IVL enrollment' do

      before do
        enrollment.kind = 'individual'
        enrollment.aasm_state= 'coverage_terminated'
        enrollment.save
      end

      context 'enrollment that already terminated with past date' do
        context 'with new termination date == enrollment effective date' do
          it 'should cancel enrollment' do
            enrollment.update_attributes(terminated_on: TimeKeeper.date_of_record - 1.day)
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated', {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, 'enrollment_action_uri' => 'urn:openhbx:terms:v1:enrollment#terminate_enrollment', 'is_trading_partner_publishable' => false})
            enrollment.cancel_terminated_enrollment(TimeKeeper.date_of_record.last_month.beginning_of_month, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq 'coverage_canceled'
            expect(enrollment.terminated_on).to eq nil
            expect(enrollment.termination_submitted_on).to eq nil
            expect(enrollment.terminate_reason).to eq nil
          end
        end
      end

      context 'enrollment that already terminated with future date' do
        context 'with new termination date == enrollment effective date' do
          it 'should cancel enrollment' do
            expect(enrollment).to receive(:notify).with('acapi.info.events.hbx_enrollment.terminated', {:reply_to=>glue_event_queue_name, "hbx_enrollment_id" => enrollment.hbx_id, "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment", "is_trading_partner_publishable" => false})
            enrollment.cancel_terminated_enrollment(TimeKeeper.date_of_record.last_month.beginning_of_month, false)
            enrollment.reload
            expect(enrollment.aasm_state).to eq 'coverage_canceled'
            expect(enrollment.terminated_on).to eq nil
            expect(enrollment.termination_submitted_on).to eq nil
            expect(enrollment.terminate_reason).to eq nil
          end
        end
      end
    end
  end
end

describe ".parent enrollments", dbclean: :around_each do

  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"

  let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month - 1.month }
  let(:effective_on) { current_effective_date }
  let(:hired_on) { TimeKeeper.date_of_record - 3.months }
  let(:employee_created_at) { hired_on }
  let(:employee_updated_at) { employee_created_at }
  let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
  let!(:sponsored_benefit) {benefit_sponsorship.benefit_applications.first.benefit_packages.first.health_sponsored_benefit}
  let!(:update_sponsored_benefit) {sponsored_benefit.update_attributes(product_package_kind: :single_product)}

  let(:aasm_state) { :active }
  let(:census_employee) do
    FactoryBot.create(:census_employee, :with_active_assignment,
                      benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile,
                      benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at,
                      updated_at: employee_updated_at)
  end

  let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
  let(:enrollment_kind) { "open_enrollment" }
  let(:special_enrollment_period_id) { nil }

  let!(:active_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      household: shop_family.latest_household,
                      coverage_kind: "health",
                      family: shop_family,
                      effective_on: effective_on + 1.month,
                      enrollment_kind: enrollment_kind,
                      kind: "employer_sponsored",
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: employee_role.id,
                      product: sponsored_benefit.reference_product,
                      aasm_state: "coverage_selected",
                      predecessor_enrollment_id: terminated_enrollment.id,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end


  let!(:terminated_enrollment) do
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
                      aasm_state: "coverage_terminated",
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                      terminated_on: effective_on.end_of_month)
  end


  context "enrollment with predecessor_enrollment_id field exists", dbclean: :around_each do
    it "should return previous contionus enrollemnt " do
      expect(active_enrollment.parent_enrollment).to eq terminated_enrollment
      expect(active_enrollment.effective_on).to eq terminated_enrollment.terminated_on + 1.day
      expect(terminated_enrollment.terminated_on).to eq active_enrollment.effective_on - 1.day
    end
  end

  context "contionus enrollments before predecessor_enrollment_id field introduced", dbclean: :around_each do

    before do
      active_enrollment.effective_on = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE
      active_enrollment.created_at = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE
      active_enrollment.save

      terminated_enrollment.effective_on = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE - 1.month
      terminated_enrollment.created_at = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE - 1.month
      terminated_enrollment.terminated_on = HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE - 1.day
      terminated_enrollment.save
    end

    it "should match & return previous contionus enrollment" do
      expect(active_enrollment.parent_enrollment).to eq terminated_enrollment
      expect(active_enrollment.effective_on).to eq HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE
      expect(terminated_enrollment.terminated_on).to eq HbxEnrollment::PREDECESSOR_ID_INTRODUCTION_DATE - 1.day
    end
  end

end

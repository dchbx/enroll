require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe BenefitApplications::AcaShopEnrollmentEligibilityPolicy, type: :model, :dbclean => :after_each do
    before(:all) do
      TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end


    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"
    include_context "setup employees with benefits"

    let!(:subject) {BenefitApplications::AcaShopEnrollmentEligibilityPolicy.new}
    let!(:benefit_application) {initial_application}
    let!(:benefit_application_update) {benefit_application.update_attributes(:fte_count => 5,
                                                                             :open_enrollment_period => Range.new(Date.today, Date.today + BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN))
    }

    describe "New model instance" do
      it "should have businese_policy" do
        expect(subject.business_policies.present?).to eq true
      end
      it "should have businese_policy named enrollment_elgibility_policy" do
        expect(subject.business_policies[:enrollment_elgibility_policy].present?).to eq true
      end
      it "should not respond to dummy businese_policy name" do
        expect(subject.business_policies[:dummy].present?).to eq false
      end
    end

    describe "Validates enrollment_elgibility_policy business policy" do
      let!(:policy_name) {:enrollment_elgibility_policy}
      let!(:policy) {subject.business_policies[policy_name]}

      context "When all the census employees are emrolled" do
        before do
          benefit_sponsorship.census_employees.each do |ce|
            family = FactoryBot.create(:family, :with_primary_family_member)
            allow(ce).to receive(:family).and_return(family)
            allow(benefit_application).to receive(:active_census_employees_under_py).and_return([ce])
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
            ce.save
          end
        end

        it "should satisfy rules" do
          expect(policy.is_satisfied?(benefit_application)).to eq true
        end
      end

      context "When less then minimum participation of the census employees are emrolled" do
        before do
          benefit_sponsorship.census_employees.limit(3).each do |ce|
            family = FactoryBot.create(:family, :with_primary_family_member)
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
            ce.save
          end
        end

        it "should falsify when rules not satified" do
          expect(policy.is_satisfied?(benefit_application)).to eq false
        end
      end

      context "When all the census employees are waived" do
        before do
          employees = []
          benefit_sponsorship.census_employees.each do |ce|
            family = FactoryBot.create(:family, :with_primary_family_member)
            allow(ce).to receive(:family).and_return(family)
            allow(ce).to receive(:is_waived_under?).and_return true
            employees << ce
          end
          allow(benefit_application).to receive(:active_census_employees_under_py).and_return(employees)
        end

        it "should fail the policy" do
          policy = subject.business_policies_for(benefit_application, :end_open_enrollment)
          expect(policy.is_satisfied?(benefit_application)).to eq false
        end
      end
    end

    describe "For business_policies_for 1/1 effective date" do

      let!(:benefit_application_update) {benefit_application.update_attributes(:fte_count => 5,
                                                                               :effective_period => Range.new(TimeKeeper.date_of_record.beginning_of_year-1.year, TimeKeeper.date_of_record.end_of_year-1.year),
                                                                               :open_enrollment_period => Range.new(Date.today, Date.today + BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN))
      }

      context "When all the census employees are emrolled" do

        before do
          benefit_sponsorship.census_employees.each do |ce|
            family = FactoryBot.create(:family, :with_primary_family_member)
            allow(ce).to receive(:family).and_return(family)
            allow(benefit_application).to receive(:active_census_employees_under_py).and_return([ce])
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
            ce.save
          end
        end

        it "should satisfy rules" do
          policy = subject.business_policies_for(benefit_application, :end_open_enrollment)
          expect(policy.is_satisfied?(benefit_application)).to eq true
        end
      end

      context "When minimum participation of the census employees are emrolled" do
        context "At-least 1.0 non-owner employee enrolled" do

          before do
            benefit_sponsorship.census_employees.each do |ce|
              family = FactoryBot.create(:family, :with_primary_family_member)
              allow(ce).to receive(:family).and_return(family)
              allow(benefit_application).to receive(:active_census_employees_under_py).and_return([ce])
              FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
              ce.save
            end
          end

          it "should pass the policy" do
            policy = subject.business_policies_for(benefit_application, :end_open_enrollment)
            expect(policy.is_satisfied?(benefit_application)).to eq true
          end
        end
      end

      context "Zero non-owner employees are enrolled" do

        let(:load_enrollments3) {benefit_sponsorship.census_employees.limit(5).each do |ce|
          ce.update_attributes(is_business_owner: true)
          ce.save
        end
        }

        it "should fail the policy" do
          policy = subject.business_policies_for(benefit_application, :end_open_enrollment)
          expect(policy.is_satisfied?(benefit_application)).to eq false
        end
      end
    end

    describe "For business_policies_for non 1/1 effective date" do
      context "When all the census employees are emrolled" do
        before do
          benefit_sponsorship.census_employees.each do |ce|
            family = FactoryBot.create(:family, :with_primary_family_member)
            allow(ce).to receive(:family).and_return(family)
            allow(benefit_application).to receive(:active_census_employees_under_py).and_return([ce])
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
            ce.save
          end
        end

        it "should satisfy rules" do
          policy = subject.business_policies_for(benefit_application, :end_open_enrollment)
          expect(policy.is_satisfied?(benefit_application)).to eq true
        end
      end

      context "When less than minimum participation of the census employees are emrolled" do

        let!(:load_enrollments) do
          benefit_sponsorship.census_employees.limit(3).each do |ce|
            person = FactoryBot.create(:person)
            family = FactoryBot.create(:family, :with_primary_family_member, person: person)
            enrollment = FactoryBot.create(:hbx_enrollment,
                                           family: family,
                                           household: family.active_household,
                                           benefit_sponsorship: benefit_sponsorship,
                                           benefit_group_assignment: ce.benefit_group_assignments.first,
                                           sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id
                                           )
            employee_role = FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: TimeKeeper.date_of_record - 2.days, person: person, census_employee: ce)
            ce.update_attributes(employee_role_id: employee_role.id)
            ce.save!
            ce.benefit_group_assignments.first.update_attributes(hbx_enrollment_id: enrollment.id)
          end
        end

        let!(:update_census_emnployee) do
          benefit_sponsorship.census_employees.limit(1).each do |ce|
            ce.update_attributes(is_business_owner: true)
            ce.save!
          end
        end

        # For 1/1 effective date minimum participation rule does not apply
        # 1+ non-owner rule does apply

        before do
          if benefit_application.start_on.yday != 1
            allow(benefit_application).to receive(:employee_participation_ratio_minimum).and_return(0.75)
          end
        end

        it "should fail the policy" do
          policy = subject.business_policies_for(benefit_application, :end_open_enrollment)
          # Making the system to default to amnesty rules for release 1.
          if benefit_application.start_on.yday == 1
            expect(policy.is_satisfied?(benefit_application)).to eq true
          else
            expect(policy.is_satisfied?(benefit_application)).to eq false
          end
        end
      end
    end
  end
end

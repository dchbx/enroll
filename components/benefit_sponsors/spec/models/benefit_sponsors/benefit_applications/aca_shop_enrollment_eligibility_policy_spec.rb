require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe BenefitApplications::AcaShopEnrollmentEligibilityPolicy, type: :model, :dbclean => :after_each do
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
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_sponsorship: benefit_sponsorship, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
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
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_sponsorship: benefit_sponsorship, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
            ce.save
          end
        end

        it "should falsify when rules not satified" do
          expect(policy.is_satisfied?(benefit_application)).to eq false
        end
      end
    end

    describe "Validates non_minimum_participation_enrollment_eligiblity_policy business policy" do

      let!(:policy_name) {:non_minimum_participation_enrollment_eligiblity_policy}
      let!(:policy) {subject.business_policies[policy_name]}

      context "When all the census employees are emrolled" do

        let!(:load_enrollments) {benefit_sponsorship.census_employees.each do |ce|
          family = FactoryBot.create(:family, :with_primary_family_member)
          FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_sponsorship: benefit_sponsorship, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
          ce.save
        end
        }

        it "should satisfy rules" do
          expect(policy.is_satisfied?(benefit_application)).to eq true
        end

      end

      context "When less then minimum participation of the census employees are emrolled" do

        let!(:load_enrollments) {benefit_sponsorship.census_employees.limit(3).each do |ce|
          family = FactoryBot.create(:family, :with_primary_family_member)
          FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_sponsorship: benefit_sponsorship, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
          ce.save
        end
        }

        it "should satisfy rules" do
          expect(policy.is_satisfied?(benefit_application)).to eq true
        end
      end
    end

    describe "For business_policies_for 1/1 effective date" do

      let!(:benefit_application_update) {benefit_application.update_attributes(:fte_count => 5,
                                                                               :effective_period => Range.new(TimeKeeper.date_of_record.beginning_of_year-1.year, TimeKeeper.date_of_record.end_of_year-1.year),
                                                                               :open_enrollment_period => Range.new(Date.today, Date.today + BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN))
      }

      context "When all the census employees are emrolled" do

        let!(:load_enrollments1) {benefit_sponsorship.census_employees.each do |ce|
          family = FactoryBot.create(:family, :with_primary_family_member)
          FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_sponsorship: benefit_sponsorship, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
          ce.save
        end
        }

        it "should satisfy rules" do
          policy = subject.business_policies_for(benefit_application, :end_open_enrollment)
          expect(policy.is_satisfied?(benefit_application)).to eq true
        end
      end

      context "When minimum participation of the census employees are emrolled" do
        context "At-least 1.0 non-owner employee enrolled" do

          let!(:load_enrollments2) {benefit_sponsorship.census_employees.limit(3).each do |ce|
            family = FactoryBot.create(:family, :with_primary_family_member)
            FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_sponsorship: benefit_sponsorship, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
            ce.save
          end
          }

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

        let!(:load_enrollments) {benefit_sponsorship.census_employees.each do |ce|
          family = FactoryBot.create(:family, :with_primary_family_member)
          FactoryBot.create(:hbx_enrollment,family: family, household: family.active_household, benefit_sponsorship: benefit_sponsorship, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
          ce.save
        end
        }

        it "should satisfy rules" do
          policy = subject.business_policies_for(benefit_application, :end_open_enrollment)
          expect(policy.is_satisfied?(benefit_application)).to eq true
        end

      end

      context "When less then minimum participation of the census employees are emrolled" do

        let!(:load_enrollments) {benefit_sponsorship.census_employees.limit(3).each do |ce|
          family = FactoryBot.create(:family, :with_primary_family_member)
          FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, benefit_sponsorship: benefit_sponsorship, benefit_group_assignment: ce.benefit_group_assignments.first, sponsored_benefit_package_id: ce.benefit_group_assignments.first.benefit_package.id)
          ce.save
        end
        }

        # For 1/1 effective date minimum participation rule does not apply
        # 1+ non-owner rule does apply
        it "should fail the policy" do
          policy = subject.business_policies_for(benefit_application, :end_open_enrollment)
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

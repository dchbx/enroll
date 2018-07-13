require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::AcaShopApplicationEligibilityPolicy, type: :model do

    let!(:subject) { BenefitApplications::AcaShopApplicationEligibilityPolicy.new }

    context "A new model instance" do
      it "should have businese_policy" do
        expect(subject.business_policies.present?).to eq true
      end
      it "should have businese_policy named passes_open_enrollment_period_policy" do
        expect(subject.business_policies[:passes_open_enrollment_period_policy].present?).to eq true
      end
      it "should not respond to dummy businese_policy name" do
        expect(subject.business_policies[:dummy].present?).to eq false
      end
   end

   context "Validates passes_open_enrollment_period_policy business policy" do

     let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application,
        :with_benefit_package,
        :fte_count => 1,
        :open_enrollment_period => Range.new(Date.today, Date.today + BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN),
      )
      }
      let!(:policy_name) { :passes_open_enrollment_period_policy }
      let!(:policy) { subject.business_policies[policy_name]}

      it "should have open_enrollment period lasting more than min" do
        expect(benefit_application.open_enrollment_length).to be >= BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN
     end

      it "should satisfy rules" do
        expect(policy.is_satisfied?(benefit_application)).to eq true
     end
  end


  context "Fails passes_open_enrollment_period_policy business policy" do
    let!(:benefit_application) { FactoryGirl.create(:benefit_sponsors_benefit_application,
       :fte_count => 3,
       :open_enrollment_period => Range.new(Date.today+5, Date.today + BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN),
     )
     }
     let!(:policy_name) { :passes_open_enrollment_period_policy }
     let!(:policy) { subject.business_policies[policy_name]}

     it "should fail rule validation" do
      expect(policy.is_satisfied?(benefit_application)).to eq false
    end
 end

  end
end

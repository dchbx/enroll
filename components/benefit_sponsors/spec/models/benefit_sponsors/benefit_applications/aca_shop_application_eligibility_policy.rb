# frozen_string_literal: true

require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::AcaShopApplicationEligibilityPolicy, type: :model, :dbclean => :after_each do

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

      let!(:benefit_application) do
        FactoryBot.create(:benefit_sponsors_benefit_application,
                          :with_benefit_package,
                          :fte_count => 1,
                          :open_enrollment_period => Range.new(Date.today, Date.today + BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN))
      end
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
      let!(:benefit_application) do
        FactoryBot.create(:benefit_sponsors_benefit_application,
                          :fte_count => 3,
                          :open_enrollment_period => Range.new(Date.today + 5, Date.today + BenefitApplications::AcaShopApplicationEligibilityPolicy::OPEN_ENROLLMENT_DAYS_MIN))
      end
      let!(:policy_name) { :passes_open_enrollment_period_policy }
      let!(:policy) { subject.business_policies[policy_name]}

      it "should fail rule validation" do
        expect(policy.is_satisfied?(benefit_application)).to eq false
      end
    end

    context 'rule within_last_day_to_publish' do
      let!(:benefit_application) { double('BenefitApplication', last_day_to_publish: last_day_to_publish, start_on: last_day_to_publish) }
      let!(:rule) { subject.business_policies[:submit_benefit_application].rules.detect{|x| x.name == :within_last_day_to_publish} }

      context 'fail' do
        let!(:last_day_to_publish) { Time.now - 1.day }
        before do
          TimeKeeper.any_instance.stub(:date_of_record).and_return(Time.now)
        end

        it "should fail rule validation" do
          expect(rule.fail.call(benefit_application)).to eq "Plan year starting on #{last_day_to_publish.to_date} must be published by #{last_day_to_publish.to_date}"
        end
      end

      context 'success' do
        let!(:last_day_to_publish) { Time.now + 1.day }
        before do
          TimeKeeper.any_instance.stub(:date_of_record).and_return(Time.now)
        end

        it "should validate successfully" do
          expect(rule.success.call(benefit_application)).to eq("Plan year was published before #{benefit_application.last_day_to_publish} on #{Time.now} ")
        end
      end
    end

  end
end

# frozen_string_literal: true

require 'rails_helper'
require File.join(Rails.root, 'spec/shared_contexts/enrollment')

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
  describe BusinessPolicies::IvlMarketPolicies::AcaIvlEnrollmentEligibilityPolicy, dbclean: :after_each do
    subject { described_class.new }

    context 'apply_aptc' do
      include_context 'setup families enrollments'

      context 'for success case' do
        before :each do
          tax_household.update_attributes!(effective_starting_on: enrollment_assisted.effective_on)
          @business_policy = subject.execute(enrollment_assisted, :apply_aptc)
        end

        it 'should return true when validated' do
          expect(@business_policy[:satisfied]).to eq true
        end

        it 'should not return any fail results' do
          expect(@business_policy[:errors]).to be_empty
        end
      end

      context 'for failure cases' do
        before :each do
          @business_policy = subject.execute(enrollment_unassisted, :apply_aptc)
        end

        it 'should return true when validated' do
          expect(@business_policy[:satisfied]).to eq false
        end

        it 'should return fail results' do
          expect(@business_policy[:errors]).to eq ['None of the shopping members are eligible for APTC']
        end
      end
    end

    context 'apply_csr' do
      include_context 'setup families enrollments'

      context 'for success case' do
        before :each do
          tax_household.update_attributes!(effective_starting_on: enrollment_assisted.effective_on)
          @business_policy = subject.execute(enrollment_assisted, :apply_aptc)
        end

        it 'should return true when validated' do
          expect(@business_policy[:satisfied]).to eq true
        end

        it 'should not return any fail results' do
          expect(@business_policy[:errors]).to be_empty
        end
      end

      context 'for failure cases' do
        context 'tax households exists' do
          before :each do
            tax_household.update_attributes!(effective_starting_on: enrollment_assisted.effective_on)
            tax_household_member1.update_attributes!(is_ia_eligible: false, is_medicaid_chip_eligible: true)
            @business_policy = subject.execute(enrollment_assisted, :apply_csr)
          end

          it 'should return true when validated' do
            expect(@business_policy[:satisfied]).to eq false
          end

          it 'should return fail results' do
            expect(@business_policy[:errors]).to eq ['One of the shopping members are ineligible for CSR']
          end
        end

        context 'tax households does not exists' do
          before :each do
            @business_policy = subject.execute(enrollment_unassisted, :apply_csr)
          end

          it 'should return true when validated' do
            expect(@business_policy[:satisfied]).to eq false
          end

          it 'should return fail results' do
            expect(@business_policy[:errors]).to eq ['One of the shopping members are ineligible for CSR']
          end
        end
      end
    end

    context 'edit_aptc' do
      include_context 'setup families enrollments'

      BusinessPolicies::IvlMarketPolicies::AcaIvlEnrollmentEligibilityPolicy::APTC_ELIGIBLE_ENROLLMENT_STATES.each do |state|
        context 'for success case' do
          before :each do
            enrollment_assisted.update_attributes(aasm_state: state)
            @business_policy = subject.execute(enrollment_assisted, :edit_aptc)
          end

          it 'should return true when validated' do
            expect(@business_policy[:satisfied]).to eq true
          end

          it 'should not return any fail results' do
            expect(@business_policy[:errors]).to be_empty
          end
        end
      end

      BusinessPolicies::IvlMarketPolicies::AcaIvlEnrollmentEligibilityPolicy::APTC_INELIGIBLE_ENROLLMENT_STATES.each do |state|
        context 'for failure cases' do
          before :each do
            enrollment_assisted.update_attributes(aasm_state: state)
            @business_policy = subject.execute(enrollment_assisted, :edit_aptc)
          end

          it 'should return true when validated' do
            expect(@business_policy[:satisfied]).to eq false
          end

          it 'should return fail results' do
            expect(@business_policy[:errors]).to eq ["Aasm state of given enrollment is #{enrollment_assisted.aasm_state} which is an invalid state"]
          end
        end
      end
    end

    context 'for invalid inputs' do
      context 'for invalid object' do
        before do
          @object = 'invalid object'
          @business_policy = subject.execute(@object, :apply_aptc)
        end

        it 'should return false' do
          expect(@business_policy[:satisfied]).to eq false
        end

        it 'should return fail results based on market kind' do
          fail_messages = ["Class of the given object is #{@object.class} and not ::HbxEnrollment"]
          expect(@business_policy[:errors]).to eq fail_messages
        end
      end

      context 'for invalid event' do
        before do
          @event = 'invalid event'
          @business_policy = subject.execute(enrollment_assisted, @event)
        end

        it 'should return false' do
          expect(@business_policy[:satisfied]).to eq false
        end

        it 'should return fail results based on market kind' do
          fail_messages = ["Invalid event: #{@event}"]
          expect(@business_policy[:errors]).to eq fail_messages
        end
      end
    end
  end
end

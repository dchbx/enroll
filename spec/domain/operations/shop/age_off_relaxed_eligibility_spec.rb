# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
require 'rails_helper'
#Test cases to check the age off relaxed eligibility operations to determine the eligibility of dependents.
module Operations
  RSpec.describe AgeOffRelaxedEligibility do
    context 'invalid relationship' do
      let(:input_params) do
        {effective_on: Date.new(2021, 2, 1),
         dob: Date.new(2021 - 26, 3, 15),
         market_key: :aca_individual_dependent_age_off,
         relationship_kind: 'parent'}
      end

      it 'should return a failure with a message' do
        expect(subject.call(input_params).failure).to eq('Invalid relationship kind')
      end
    end

    context 'with different ages' do
      context 'age is just below 26 when compared with effective_date' do
        let(:input_params) do
          {effective_on: Date.new(2021, 2, 1),
           dob: Date.new(2021 - 26, 3, 15),
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        context 'age off period is annual' do
          it 'should return success' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
          end
        end

        context 'age off period is monthly' do
          let(:aca_ivl_period_setting) do
            EnrollRegistry[:aca_individual_dependent_age_off].setting(:period)
          end

          before do
            allow(aca_ivl_period_setting).to receive(:item).and_return(:monthly)
          end

          it 'should return success' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
          end
        end
      end

      context 'age is just above 26 and below 27 when compared with effective_date' do
        let(:input_params) do
          {effective_on: Date.new(2021, 2, 1),
           dob: Date.new(2021 - 26, 1, 1),
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        it 'should return Success' do
          expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
        end

        context 'age off period is monthly' do
          let(:aca_ivl_period_setting) do
            EnrollRegistry[:aca_individual_dependent_age_off].setting(:period)
          end

          before do
            allow(aca_ivl_period_setting).to receive(:item).and_return(:monthly)
          end

          it 'should return failure' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
          end
        end
      end

      context 'age is just above 27 when compared with effective_date' do
        let(:input_params) do
          {effective_on: Date.new(2021, 1, 2),
           dob: Date.new(2021 - 27, 1, 1),
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        it 'should return Failure' do
          expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
        end

        context 'age off period is monthly' do
          let(:aca_ivl_period_setting) do
            EnrollRegistry[:aca_individual_dependent_age_off].setting(:period)
          end

          before do
            allow(aca_ivl_period_setting).to receive(:item).and_return(:monthly)
          end

          it 'should return failure' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
          end
        end
      end

      context 'age is exactly 26 when compared with effective_date' do
        let(:input_params) do
          {effective_on: Date.new(2021, 1, 1),
           dob: Date.new(2021 - 26, 1, 1),
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        it 'should return success' do
          expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
        end

        context 'age off period is monthly' do
          let(:aca_ivl_period_setting) do
            EnrollRegistry[:aca_individual_dependent_age_off].setting(:period)
          end

          before do
            allow(aca_ivl_period_setting).to receive(:item).and_return(:monthly)
          end

          it 'should return success' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
          end
        end
      end

      context 'additional tests' do
        context 'ivl annual' do
          context 'effective_on and dob are same' do
            let(:input_params) do
              {effective_on: Date.new(2021, 1, 1),
               dob: Date.new(1995, 1, 1),
               market_key: :aca_individual_dependent_age_off,
               relationship_kind: 'child'}
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'effective_on falls after dob' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               dob: Date.new(1995, 1, 1),
               market_key: :aca_individual_dependent_age_off,
               relationship_kind: 'child'}
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'dob falls after effective_on' do
            let(:input_params) do
              {effective_on: Date.new(2021, 1, 1),
               dob: Date.new(1994, 11, 17),
               market_key: :aca_fehb_dependent_age_off,
               relationship_kind: 'child'}
            end

            it 'should return failure' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
            end
          end
        end

        context 'shop annual' do
          context 'effective_on and dob are same' do
            let(:input_params) do
              {effective_on: Date.new(2021, 1, 1),
               dob: Date.new(1995, 1, 1),
               market_key: :aca_shop_dependent_age_off,
               relationship_kind: 'child'}
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'effective_on falls after dob' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               dob: Date.new(1995, 1, 1),
               market_key: :aca_shop_dependent_age_off,
               relationship_kind: 'child'}
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end
        end

        context 'fehb monthly' do
          context 'effective_on and dob are same' do
            let(:input_params) do
              {effective_on: Date.new(2021, 1, 1),
               dob: Date.new(1995, 1, 1),
               market_key: :aca_fehb_dependent_age_off,
               relationship_kind: 'child'}
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'effective_on falls after dob aged just above 26 and below 27' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               dob: Date.new(1995, 1, 1),
               market_key: :aca_fehb_dependent_age_off,
               relationship_kind: 'child'}
            end

            it 'should return failure' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
            end
          end

          context 'effective_on on falls after dob aged above 27' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               dob: Date.new(1994, 1, 23),
               market_key: :aca_fehb_dependent_age_off,
               relationship_kind: 'child'}
            end

            it 'should return failure' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
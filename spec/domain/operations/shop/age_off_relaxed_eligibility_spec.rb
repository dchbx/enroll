# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
require 'rails_helper'
#Test cases to check the age off relaxed eligibility operations to determine the eligibility of dependents.
module Operations
  RSpec.describe AgeOffRelaxedEligibility do

    let!(:person) {FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)}
    let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:primary_fm) {family.primary_applicant}
    let!(:household) {family.active_household}
    let!(:enrollment) do
      enr = FactoryBot.create(:hbx_enrollment, family: family, household: household, effective_on: Date.new(2021, 1, 1))
      FactoryBot.create(:hbx_enrollment_member, applicant_id: primary_fm.id, hbx_enrollment: enr)
      enr
    end

    context 'invalid relationship' do
      let(:input_params) do
        {effective_on: Date.new(2021, 2, 1),
         family_member: primary_fm,
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
           family_member: primary_fm,
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        before do
          enrollment.update_attributes(kind: "individual")
          person.update_attributes(dob: Date.new(2021 - 26, 3, 15))
        end

        context 'age off period is annual' do

          it 'should return failure when person is not previuosly enrolled' do
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
           family_member: primary_fm,
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        before do
          enrollment.update_attributes(kind: "individual")
          person.update_attributes(dob: Date.new(2021 - 26, 1, 1))
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
           family_member: primary_fm,
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        before do
          person.update_attributes(dob: Date.new(2021 - 27, 1, 1))
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
           family_member: primary_fm,
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        before do
          enrollment.update_attributes(kind: "individual")
          person.update_attributes(dob: Date.new(2021 - 26, 1, 1))
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

      context 'age is exactly 26 when compared with effective_date and does not have continuous coverage' do
        let(:input_params) do
          {effective_on: Date.new(2021, 1, 1),
           family_member: primary_fm,
           market_key: :aca_individual_dependent_age_off,
           relationship_kind: 'child'}
        end

        before do
          person.update_attributes(dob: Date.new(2021 - 26, 1, 1))
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

          it 'should return Failure' do
            expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
          end
        end
      end

      context 'additional tests' do
        context 'ivl annual' do
          context 'effective_on and dob are same' do
            let(:input_params) do
              {effective_on: Date.new(2021, 1, 1),
               family_member: primary_fm,
               market_key: :aca_individual_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              enrollment.update_attributes(kind: "individual")
              person.update_attributes(dob: Date.new(1995, 1, 1))
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'effective_on falls after dob' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               family_member: primary_fm,
               market_key: :aca_individual_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              enrollment.update_attributes(kind: "individual")
              person.update_attributes(dob: Date.new(1995, 1, 1))
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'effective_on falls before dob' do
            let(:input_params) do
              {effective_on: Date.new(2021, 1, 14),
               family_member: primary_fm,
               market_key: :aca_individual_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              enrollment.update_attributes(kind: "individual")
              person.update_attributes(dob: Date.new(1995, 1, 12))
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'dob falls after effective_on' do
            let(:input_params) do
              {effective_on: Date.new(2021, 1, 1),
               family_member: primary_fm,
               market_key: :aca_fehb_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              person.update_attributes(dob: Date.new(1994, 11, 17))
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
               family_member: primary_fm,
               market_key: :aca_shop_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              person.update_attributes(dob: Date.new(1995, 1, 1))
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'effective_on falls after dob' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               family_member: primary_fm,
               market_key: :aca_shop_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              person.update_attributes(dob: Date.new(1995, 1, 1))
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
               family_member: primary_fm,
               market_key: :aca_fehb_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              person.update_attributes(dob: Date.new(1995, 1, 1))
            end

            it 'should return success' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'effective_on falls after dob aged just above 26 and below 27' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               family_member: primary_fm,
               market_key: :aca_fehb_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              person.update_attributes(dob: Date.new(1995, 1, 1))
            end

            it 'should return failure' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
            end
          end

          context 'effective_on on falls after dob aged above 27' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               family_member: primary_fm,
               market_key: :aca_fehb_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              person.update_attributes(dob: Date.new(1994, 1, 23))
            end

            it 'should return failure' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Failure)
            end
          end

          context 'returns success when dep turns 26 on effective month with previous coverage' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               family_member: primary_fm,
               market_key: :aca_shop_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              person.update_attributes(dob: Date.new(1995, 2, 15))
            end

            it 'should return failure' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end

          context 'returns success when dep turns 26 on effective month without previous coverage' do
            let(:input_params) do
              {effective_on: Date.new(2021, 2, 1),
               family_member: primary_fm,
               market_key: :aca_shop_dependent_age_off,
               relationship_kind: 'child'}
            end

            before do
              enrollment.hbx_enrollment_members.delete_all
              person.update_attributes(dob: Date.new(1995, 2, 15))
            end

            it 'should return failure' do
              expect(subject.call(input_params)).to be_a(Dry::Monads::Result::Success)
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
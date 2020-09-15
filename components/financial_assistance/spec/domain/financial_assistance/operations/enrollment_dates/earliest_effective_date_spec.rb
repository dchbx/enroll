# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::EnrollmentDates::EarliestEffectiveDate do


  let(:result) { subject.call(application_date: application_date) }

  describe 'Earliest Effective Date Operation' do

    context 'when passed date outside open enrollment' do
      context 'and before enrollment monthly due date' do
        let(:application_date) { Date.new(Date.today.year, 5, 5)}


        it 'should return next month begin as effective date' do
          expect(result).to be_a(Dry::Monads::Result::Success)
          expect(result.success).to eq application_date.next_month.beginning_of_month
        end
      end

      context 'and after enrollment monthly due date' do
        let(:application_date) { Date.new(Date.today.year, 5, 16)}

        it 'should return month after next month effective date' do
          expect(result).to be_a(Dry::Monads::Result::Success)
          expect(result.success).to eq (application_date.next_month + 1.month).beginning_of_month
        end
      end
    end

    context 'when passed date with in open enrollment' do
      context 'and before enrollment monthly due date' do
        let(:application_date) { Date.new(Date.today.year, 12, 15)}

        it 'should return next year begin date' do
          expect(result).to be_a(Dry::Monads::Result::Success)
          expect(result.success).to eq (application_date.end_of_year + 1.day)
        end
      end

      context 'and after enrollment monthly due date' do
        let(:application_date) { Date.new(Date.today.year, 12, 16)}

        it 'should return next year begin date' do
          expect(result).to be_a(Dry::Monads::Result::Success)
          expect(result.success).to eq (application_date.end_of_year + 1.month + 1.day)
        end
      end
    end
  end
end

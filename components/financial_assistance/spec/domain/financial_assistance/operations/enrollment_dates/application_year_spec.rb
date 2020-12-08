# frozen_string_literal: true

# Date.today converteed to TimeKeeper.date_of_record

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::EnrollmentDates::ApplicationYear do


  let(:result) { subject.call(application_date: application_date) }

  describe 'Application Date Operation' do

    context 'when passed date outside open enrollment' do
      let(:application_date) { Date.new(TimeKeeper.date_of_record.year, 5, 1)}

      it 'return current calender year' do
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.success).to eq application_date.year
      end
    end

    context 'when passed date with in open enrollment' do
      let(:application_date) { Date.new(TimeKeeper.date_of_record.year, 12, 1)}

      it 'should return next calender year' do
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.success).to eq application_date.year + 1
      end
    end
  end
end

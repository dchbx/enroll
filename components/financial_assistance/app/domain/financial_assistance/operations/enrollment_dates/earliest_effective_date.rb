# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module EnrollmentDates
      class EarliestEffectiveDate
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] application_date Application Created Date
        # @return [ Date ] earliest_effective_date Application Earliest Effective Date
        def call(application_date: TimeKeeper.date_of_record)
          earliest_effective_date = yield calculate(application_date)

          Success(earliest_effective_date)
        end

        private

        def calculate(application_date)
          effective_date = if application_date.mday <= FinancialAssistanceRegistry[:enrollment_due_day_of_month].item
            application_date.end_of_month + 1.day
          else
            application_date.next_month.end_of_month + 1.day
          end

          start_on = if application_date < new_year_effective_date(application_date)
            application_date.beginning_of_year
          else
            application_date.next_year.beginning_of_year
          end

          effective_date = [[effective_date, start_on].max, start_on.end_of_year].min

          Success(effective_date)
        end

        def new_year_effective_date(application_date)
          date_values = FinancialAssistanceRegistry[:application_new_year_effective_date].item
          Date.new(application_date.year, date_values['month_of_year'], date_values['day_of_month'])
        end
      end
    end
  end
end

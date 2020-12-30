# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module EnrollmentDates
      class ApplicationYear
        send(:include, Dry::Monads[:result, :do])

        # @param [ Date ] application_date Application Created Date
        # @return [ Date ] earliest_effective_date Application Earliest Effective Date
        def call(application_date: TimeKeeper.date_of_record)
          earliest_effective_date = yield calculate(application_date)

          Success(earliest_effective_date)
        end

        private

        def calculate(application_date)
          calender_year = application_date.year
          enrollment_start_on_year = new_year_effective_date(application_date)

          application_year = if application_date >= enrollment_start_on_year && calender_year == enrollment_start_on_year.year
            calender_year + 1
          else
            calender_year
          end

          Success(application_year)
        end

        def new_year_effective_date(application_date)
          date_values = FinancialAssistanceRegistry[:application_new_year_effective_date].item
          Date.new(application_date.year, date_values['month_of_year'], date_values['day_of_month'])
        end
      end
    end
  end
end

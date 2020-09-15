# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class CreateOrUpdate
        send(:include, Dry::Monads[:result, :do])

        def call(params:, application:)
          values = yield validate(params)
          match = yield match(application, values)
          result = yield update(match, values)

          Success(result)
        end

        private

        def validate(params)
          result = ::FinancialAssistance::Validators::ApplicationContract.new.call(params)


          if result.success?
            Success(result.to_h)
          else
            Failure(result)
          end
        end

        def match_or_build(application, values)
          result = ::FinancialAssistance::Operations::Applicant::Match.new.call(params: values, application: application)

          if result.success?
            Success(result.success)
          else
            Success(application.applicants.build(values))
          end
        end

        def update(applicant, values)
          match.assign_attributes(values)

          if match.save
            Success(match)
          else
            Failure(match.errors)
          end
        end
      end
    end
  end
end
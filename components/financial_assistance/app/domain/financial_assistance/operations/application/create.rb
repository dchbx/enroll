# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Application
      class Create
        send(:include, Dry::Monads[:result, :do])

        def call(params:)
          values = yield validate(params)
          result = yield create(values)

          Success(result)
        end

        private

        def validate(params)
          result = FinancialAssistance::Validators::ApplicationContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure(result)
          end
        end

        def create(values)
          application = ::FinancialAssistance::Application.new(values.except(:applicants))

          applicants_results = values[:applicants].map do |applicant|
            FinancialAssistance::Operations::Applicant::Build.new.call(params: applicant.merge(application: application))
          end

          applicants_results.map do |result|
            result.success? ? application.applicants.build(result.success.to_h) : result.failure
          end

          if application.save
            Success(application.id)
          else
            Failure(application.errors)
          end
        end
      end
    end
  end
end
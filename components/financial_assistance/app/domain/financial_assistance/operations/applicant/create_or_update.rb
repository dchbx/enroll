# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applicant
      class CreateOrUpdate
        send(:include, Dry::Monads[:result, :do])

        def call(params:, family_id:)
          values = yield validate(params)
          application = yield find_draft_application(family_id)
          applicant = yield match_or_build(values, application)
          result = yield update(applicant, values)

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

        def find_draft_application(family_id)
          application =  ::FinancialAssistance::Application.where(family_id: family_id, aasm_state: 'draft').first
          if application
            Success(application)
          else
            Failure("Application Not Found")
          end
        end

        def match_or_build(values, application)
          result = ::FinancialAssistance::Operations::Applicant::Match.new.call(params: values, application: application)

          if result.success?
            Success(result.success)
          else
            Success(application.applicants.build(values))
          end
        end

        def update(applicant, values)
          applicant.assign_attributes(values)

          if applicant.save
            Success(applicant)
          else
            Failure(applicant.errors)
          end
        end
      end
    end
  end
end

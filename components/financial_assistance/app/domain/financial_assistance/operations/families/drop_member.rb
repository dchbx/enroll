# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Families
      class DropMember
        send(:include, Dry::Monads[:result, :do])

        def call(params:)
          values = yield validate(params)
          applicant_params = yield build(values)
          result = yield drop_family_member(applicant_params)

          Success(result)
        end

        private

        def validate(params)
          result = ::FinancialAssistance::Validators::ApplicantContract.new.call(params)

          if result.success?
            Success(result.to_h)
          else
            Failure(result)
          end
        end

        def build(values)
          result = FinancialAssistance::Entities::Applicant.new(values)

          Success(result)
        end

        def drop_family_member(applicant_params)
          ::Operations::Families::DropFamilyMember.new.call(params: applicant_params)

          Success('A successful call was made to enroll to drop a family member')
        rescue StandardError => e
          Failure(e.message)
        end
      end
    end
  end
end

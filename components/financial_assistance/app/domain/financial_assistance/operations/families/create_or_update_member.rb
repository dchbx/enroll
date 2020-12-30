# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Families
      class CreateOrUpdateMember
        send(:include, Dry::Monads[:result, :do])

        def call(params:)
          values = yield validate(params[:applicant_params])
          applicant_params = yield build(values)
          result = yield create_or_update_family_member( applicant_params.to_h.merge(family_id: params[:family_id]))

          Success(result)
        end

        private

        def validate(params)
          result = FinancialAssistance::Validators::ApplicantContract.new.call(params)

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

        def create_or_update_family_member(applicant)
          begin
            result = ::Operations::Families::CreateOrUpdateFamilyMember.new.call(applicant)
            return result if result.success?
          rescue StandardError => e
            Failure(e.message)
          end
          Success('A successful call was made to enroll to create or update a family member')
        end
      end
    end
  end
end

# frozen_string_literal: true

module Validators
  module Families
    class EligibilityDeterminationContract < Dry::Validation::Contract

      params do
        required(:family_id).filled(Types::Bson)
        required(:assistance_year).filled(:integer)
        required(:integrated_case_id).filled(:string)
        required(:benchmark_product_id).filled(Types::Bson)
        required(:applicants).array(:hash)
        required(:eligibility_determinations).array(:hash)
      end

      rule(:family_id) do
        if key? && value
          result = Operations::Families::Find.new.call(id: values[:family_id])
          key.failure(text: 'invalid family_id', error: result.errors.to_h) if result&.failure?
        end
      end

      rule(:applicants).each do  |key, value|
        if key? && value
          if value.is_a?(Hash)
            result = Validators::Families::ApplicantContract.new.call(value)
            key.failure(text: "invalid applicant", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid applicant. Expected a hash.")
          end
        end
      end

      rule(:eligibility_determinations).each do  |key, value|
        if key? && value
          if value.is_a?(Hash)
            result = Validators::Families::DeterminationContract.new.call(value)
            key.failure(text: "invalid determination", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid determination. Expected a hash.")
          end
        end
      end
    end
  end
end

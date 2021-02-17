# frozen_string_literal: true

module Operations
  module BenefitGroupAssignments
    # This class initializes a benefit_group_assignment entity after
    # validating the incoming benefit_group_assignment params.
    class Build
      include Dry::Monads[:result, :do]

      # @param [ Hash ] benefit_group_assignment attributes
      # @return [ ::Entities::BenefitGroupAssignments::BenefitGroupAssignment ] benefit_group_assignment
      def call(params)
        values = yield validate(params)
        entity = yield initialize_entity(values)

        Success(entity)
      end

      private

      def validate(params)
        contract_result = ::Validators::BenefitGroupAssignments::BenefitGroupAssignmentContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def initialize_entity(values)
        Success(::Entities::BenefitGroupAssignments::BenefitGroupAssignment.new(values.to_h))
      end
    end
  end
end

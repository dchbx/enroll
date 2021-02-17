# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module HbxEnrollments
    # This class initializes a hbx_enrollment entity after
    # validating the incoming hbx_enrollment params.
    class Build
      include Dry::Monads[:result, :do]

      # @param [ Hash ] hbx_enrollment attributes
      # @return [ ::Entities::HbxEnrollments::HbxEnrollment ] hbx_enrollment
      def call(params)
        values = yield validate(params)
        entity = yield initialize_entity(values)

        Success(entity)
      end

      private

      def validate(params)
        contract_result = ::Validators::HbxEnrollments::HbxEnrollmentContract.new.call(params)
        contract_result.success? ? Success(contract_result.to_h) : Failure(contract_result.errors)
      end

      def initialize_entity(values)
        Success(::Entities::HbxEnrollments::HbxEnrollment.new(values.to_h))
      end
    end
  end
end

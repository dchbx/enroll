# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
# require 'aca_entities'
require 'aca_entities/operations/families/process_mcr_application'
require 'aca_entities/ffe/operations/mcr_to/family'

module Operations
  module Ffe
    # operation to transform mcr data to enroll format
    class TransformApplication
      send(:include, Dry::Monads[:result, :do])
      send(:include, Dry::Monads[:try])

      # @param [ Hash] mcr_application_payload to transform
      # @return [ Hash ] family_hash
      # api public
      def call(app_payload)
        family_params = yield transform(app_payload)
        validated_params = yield validate(family_params)
        yield find(validated_params)

        Success(validated_params)
      end

      private

      def find(validated_params)
        result = Operations::Families::Find.new.call(ext_app_id: validated_params.to_h[:hbx_id])

        result.success? ? Failure(result) : Success(result)
      end

      def transform(app_payload)
        try do
          AcaEntities::Operations::Families::ProcessMcrApplication.new(source_hash: app_payload, worker: :single).call
        end.to_result
      end

      def validate(family_params)
        # TODO: write new entoties and contracts for family hash validation
        Success(family_params)
      end
    end
  end
end

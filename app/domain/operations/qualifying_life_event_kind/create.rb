# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Create
      include Dry::Monads[:result, :do]

      def call(qle_create_params)
        merged_params    = yield merge_additional_params(qle_create_params)
        validated_params = yield validate_params(merged_params)
        entity_object    = yield initialize_entity(validated_params)
        create(entity_object)
      end

      private

      def merge_additional_params(params)
        params.merge!({ordinal_position: 0})
        params.merge!({reason: params[:other_reason]}) if params['reason'] == 'other'
        Success(params)
      end

      def validate_params(merged_params)
        result = ::Validators::QualifyingLifeEventKind::QlekContract.new.call(merged_params)

        if result.success?
          Success(result)
        else
          errors = result.errors.to_h.values.flatten
          Failure(errors)
        end
      end

      def initialize_entity(validated_params)
        result = ::Entities::QualifyingLifeEventKind.new(validated_params.to_h)
        Success(result)
      end

      def create(entity_object)
        model_params = entity_object.to_h
        qlek = ::QualifyingLifeEventKind.new(model_params)
        qlek.save!
        Success(qlek)
      end

    end
  end
end

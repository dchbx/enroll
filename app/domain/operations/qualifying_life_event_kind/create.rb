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

      def merge_additional_params(qle_create_params)
        max_ordinal_position = fetch_max_ordinal_position_by_market(qle_create_params[:market_kind])
        params = qle_create_params.merge({ ordinal_position: (max_ordinal_position + 1),
                                           market_kind: qle_create_params[:market_kind].downcase})

        Success(fix_date_params(params))
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
        ::QualifyingLifeEventKind.new(model_params).save!
        # TODO: return created object.
        Success(['A new SEP Type was successfully created.'])
      end

      def fetch_max_ordinal_position_by_market(market_kind)
        qleks = ::QualifyingLifeEventKind.by_market_kind(market_kind)
        qleks.pluck(:ordinal_position).max || 0
      end

      # TODO: refactor code to send dates in dd/mm/yyyy or fix the contract to store the date from mm/dd/yyyy format
      def fix_date_params(params)
        # TODO: use parse to fix the issue.
        start_on = params[:start_on]
        start_on = "#{start_on.split('/').second}/#{start_on.split('/').first}/#{start_on.split('/').last}"
        end_on = params[:end_on]
        end_on = "#{end_on.split('/').second}/#{end_on.split('/').first}/#{end_on.split('/').last}"

        params.merge({start_on: start_on, end_on: end_on})
      end

    end
  end
end

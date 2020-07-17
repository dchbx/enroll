# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Create
      include Dry::Monads[:result, :do]

      def call(params)
        values = yield validate(params)
        entity = yield initialize_entity(values)
        qle    = yield persist_data(entity)

        Success(qle)
      end

      private

      def validate(params)
        result = ::Validators::QualifyingLifeEventKind::QlekContract.new.call(params)
 
        if result.success?
          Success(result)
        else
          errors = result.errors.to_h.values.flatten
          Failure([result, errors])
        end
      end

      def initialize_entity(values)
        result = ::Entities::QualifyingLifeEventKind.new(values.to_h)

        Success(result)
      end

      def persist_data(entity)
        qle = ::QualifyingLifeEventKind.new(entity.to_h)
        qle.save!
        update_reason_types(qle)

        Success(qle)
      end

      def update_reason_types(qle)
        const_name = "#{qle.market_kind.humanize}QleReasons"
        const_with_namespace = "Types::#{const_name}"
        reasons = const_with_namespace.constantize.values

        if reasons.exclude?(qle.reason)
          Types.send(:remove_const, const_name)
          Types.const_set(const_name, Types::Coercible::String.enum(*(reasons + [qle.reason])))
        end
      end
    end
  end
end

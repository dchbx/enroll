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

        Success(qle)
      end
    end
  end
end

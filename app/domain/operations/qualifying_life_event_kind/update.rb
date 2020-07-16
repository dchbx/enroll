# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Update < Create
      include Dry::Monads[:result, :do]

      def call(params)
        values = yield validate(params)
        entity = yield initialize_entity(values)
        qle    = yield persist_data(entity, params['_id'])

        Success(qle)
      end

      private

      def persist_data(entity, obj_id)
        qle = ::QualifyingLifeEventKind.find(obj_id)
        qle.assign_attributes(entity.to_h)
        qle.save!

        Success(qle)
      end
    end
  end
end

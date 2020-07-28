# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module QualifyingLifeEventKind
    class Persist
      include Dry::Monads[:result, :do]

      def call(params:)
        values = yield validate(params)
        entity = yield initialize_entity(values)
        qle    = yield persist_data(entity, params)
        publish_qle(qle, params)
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

      def persist_data(entity, params)
        if params['_id']
          qle = ::QualifyingLifeEventKind.find(params['_id'])
          qle.assign_attributes(entity.to_h)
          qle.save!
        else
          qle = ::QualifyingLifeEventKind.new(entity.to_h)
          qle.save!
        end

        Success(qle)
      end

      def publish_qle(qle, params)
        qle.publish! if params[:publish] == 'Publish' && qle.may_publish?
        Success(qle)
      end
    end
  end
end


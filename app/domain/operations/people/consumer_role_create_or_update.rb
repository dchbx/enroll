# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class ConsumerRoleCreateOrUpdate
      include Dry::Monads[:result, :do]

      def call(params:)
        values = yield validate(params[:applicant_params])
        consumer_role_params = yield create_entity(values)
        result = yield create_consumer_role(consumer_role_params, params[:family_member])

        Success(result)
      end

      private

      def validate(params)
        result = Validators::Families::ConsumerRoleContract.new.call(params)

        if result.success?
          Success(result)
        else
          Failure(result)
        end
      end

      def create_entity(values)
        result = Entities::ConsumerRole.new(values.to_h)

        if result.success?
          Success(result)
        else
          Failure(result)
        end
      end

      def create_consumer_role(consumer_role_params, family_member)
        result = family_member.family.build_consumer_role(family_member, consumer_role_params)

        if result.success?
          Success(result)
        else
          Failure(result)
        end
      end
    end
  end
end


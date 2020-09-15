# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module People
    class CreateOrUpdateConsumerRole
      include Dry::Monads[:result, :do]

      def call(params:)
        values = yield validate(params[:applicant_params])
        entity = yield create_entity(values)
        result = yield create_consumer_role(entity, params[:family_member])

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

        Success(result)
      end

      def create_consumer_role(entity, family_member)
        person = family_member.person
        
        if person.consumer_role.present?
          person.consumer_role.assign_attributes(entity.to_h)
        else
          person.build_consumer_role({:is_applicant => false}.merge(entity.to_h))
        end
        person.save!
        
        Success(person.consumer_role)
      rescue StandardError => e
        Failure("Consumer role creation failed: #{e}")
      end
    end
  end
end

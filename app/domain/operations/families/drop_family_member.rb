# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class DropFamilyMember
      send(:include, Dry::Monads[:result, :do])

      #family id and family member id
      def call(params:)
        values = yield validate(params)
        result = yield drop_member(values)

        Success(result)
      end

      private

      def validate(params)
      end

      def drop_member(family_member)
        #family_member.upate_attributes(is_active: false)

        Success(family_member)
        Faliure("failed to drop family_member")
      end

    end
  end
end

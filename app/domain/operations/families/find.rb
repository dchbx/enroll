# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class Find
      send(:include, Dry::Monads[:result, :do])

      def call(id:)
        family_id = yield validate(id)
        family    = yield find_family(family_id)

        Success(family)
      end

      private

      def validate(id)
        if id&.is_a?(BSON::ObjectId)
          Success(id)
        elsif id.present?
          Success(id)
        else
          Failure('family_id is expected in BSON format')
        end
      end

      def find_family(family_id)
        family =  if id&.is_a?(BSON::ObjectId)
                    Family.find(family_id)
                  elsif id.present?
                    Family.where(hbx_id: family_id).first
                  end

        family.present? ? Success(family) : Failure("Unable to find Family with ID #{family_id}.")
      rescue StandardError
        Failure("Unable to find Family with ID #{family_id}.")
      end


      # 1- rule to check for family
    end
  end
end

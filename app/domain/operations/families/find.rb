# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class Find
      send(:include, Dry::Monads[:result, :do])

      def call(*args)
        obj_id = args.first[:id].present? ? args.first[:id] : args.first[:ext_app_id]
        family_id = yield validate(obj_id)
        family    = yield find_family(family_id)

        Success(family)
      end

      private

      def validate(id)
        if id.present? & (id.is_a?(BSON::ObjectId) || id.is_a?(String))
          Success(id)
        else
          Failure('id is nil or not in BSON format')
        end
      end

      def find_family(family_id)
        family =  if family_id.present? & family_id.is_a?(BSON::ObjectId)
                    Family.find(family_id)
                  elsif family_id.present?
                    Family.where(ext_app_id: family_id).first
                  end

        family.present? ? Success(family) : Failure("Unable to find Family with ID #{family_id}.")
      rescue StandardError
        Failure("Unable to find Family with ID #{family_id}.")
      end


      # 1- rule to check for family
    end
  end
end

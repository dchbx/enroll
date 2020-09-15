# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class Find
      send(:include, Dry::Monads[:result, :do])

      def call(id:)
        #validate
        family = yield find_family(id)

        Success(family)
      end

      private

      def find_family(family_id)
        family = Family.find(family_id)
        Success(family)
      rescue StandardError
        Failure("Unable to find Family with ID #{family_id}.")
      end


      # 1- rule to check for family
    end
  end
end

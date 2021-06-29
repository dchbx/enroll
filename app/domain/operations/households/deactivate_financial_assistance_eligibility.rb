# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Households
    class DeactivateFinancialAssistanceEligibility
      send(:include, Dry::Monads[:result, :do])

      #params: {family_id , date}
      def call(params:)
        values = yield validate(params)
        result = yield execute(values)

        Success(result)
      end

      private

      def validate(params)
        if params[:family_id].is_a?(BSON::ObjectId) && params[:date].present?
          Success(params)
        else
          Failure('family_id is expected in BSON format and date in required')
        end
      end

      # should not fail for UQHP cases too
      # returns Success(nil)
      def execute(values)
        family = Operations::Families::Find.new.call(id: BSON::ObjectId(values[:family_id]))
        tax_households = family.success.active_household.latest_active_tax_households
        result = tax_households.update_all(effective_ending_on: values[:date]) if tax_households.present?

        Success(result)
      end
    end
  end
end

# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Households
    class DeactivateFinancialAssistanceEligibility
      send(:include, Dry::Monads[:result, :do])

      def call(family_id:, date:)
        family = yield find_family(family_id)
        tax_households = yield find_tax_households(family, date)
        result = yield deactivate_tax_households(tax_households, date)

        Success(result)
      end

      private

      def find_family(family_id)
        family = Family.find(id: family_id)

        Success(family)
      rescue Mongoid::Errors::DocumentNotFound
        Failure("Unable to find family with ID #{family_id}")
      end

      def find_tax_households(family, date)
        tax_households = family.active_household.latest_tax_households_with_year(date.year)

        if tax_households.present?
          Success(tax_households)
        else
          Failure('Unable to find active tax_households')
        end
      end

      def deactivate_tax_households(tax_households, date)
        result = tax_households.update_all(effective_ending_on: date)

        Success(result)
      rescue StandardError
        Failure('Failed to update tax households')
      end
    end
  end
end

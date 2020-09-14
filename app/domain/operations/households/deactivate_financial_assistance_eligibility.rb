# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Households
    class DeactivateFinancialAssistanceEligibility
      send(:include, Dry::Monads[:result, :do])

      #family_id , date
      def call(params:)
        values = validate(params)


        Success(result)
      end

      private

      def validate(params)
        #decouple params
        #return  date and family id ---fail for not found family or invalid date format

      end

      def test
        family = yield find_family(family_id)
        tax_households = yield find_tax_households(family, date)
        result = yield deactivate_tax_households(tax_households, date)

      end

      def find_family(family_id)
        family = Family.find(family_id)

        Success(family)
      rescue Mongoid::Errors::DocumentNotFound
        Failure("Unable to find family with ID #{family_id}")
      end

      def find_tax_households(family, date)
        tax_households = family.active_household.latest_tax_households_with_year(date.year)

        #check for success format
        Success('message.....')
      end

      def deactivate_tax_households(tax_households, date)
        result = tax_households.update_all(effective_ending_on: date)

        #check for success format
        Success("message....")
      end
    end
  end
end

# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Organizations
      module OrganizationForms
        #Contract is to validate submitted params for profile creation
        class ProfileFormContract < Dry::Validation::Contract
          params do
            required(:profile_type).filled(:string)
            optional(:market_kind).filled(:string)
            optional(:languages_spoken).filled(:array)
            optional(:working_hours).filled(:string)
            optional(:accept_new_clients).filled(:string)
            required(:office_locations_attributes).value(:array, min_size?: 1)

            before(:value_coercer) do |result|
              result_hash = result.to_h
              office_location_array = []
              office_locations = result_hash[:office_locations_attributes]
              office_locations.each do |_key, value|
                symbolized_keys = value.to_h.deep_symbolize_keys!
                office_location_array << {address: symbolized_keys[:address], phone: symbolized_keys[:phone]}
              end
              result_hash[:office_locations_attributes] = office_location_array
            end
          end

          rule(:market_kind) do
            key.failure('Please enter market kind') if values[:profile_type] != 'benefit_sponsor' && value.blank?
          end

          rule(:office_locations_attributes).each do
            if key? && value
              result = BenefitSponsors::Validators::OfficeLocations::OfficeLocationContract.new.call(value)
              key.failure(text: "invalid office location params", error: result.errors.to_h) if result&.failure?
            end
          end
        end
      end
    end
  end
end

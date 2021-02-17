# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module BenefitApplications
      class BenefitApplicationContract < Dry::Validation::Contract

        params do
          optional(:expiration_date).maybe(:date)
          required(:effective_period).filled(type?: Range)
          required(:open_enrollment_period).filled(type?: Range)
          optional(:terminated_on).maybe(:date)
          required(:aasm_state).filled(:symbol)
          optional(:fte_count).maybe(:integer)
          optional(:pte_count).maybe(:integer)
          optional(:msp_count).maybe(:integer)
          optional(:recorded_sic_code).maybe(:string)
          optional(:predecessor_id).maybe(Types::Bson)
          required(:recorded_rating_area_id).filled(Types::Bson)
          required(:recorded_service_area_ids).filled(:array)
          required(:benefit_sponsor_catalog_id).filled(Types::Bson)
          optional(:termination_kind).maybe(:string)
          optional(:termination_reason).maybe(:string)
          optional(:reinstated_id).maybe(Types::Bson)

          optional(:benefit_packages).array(:hash)

          before(:value_coercer) do |result|
            result_hash = result.to_h
            if result_hash[:open_enrollment_period].is_a?(Hash)
              result_hash[:open_enrollment_period].deep_symbolize_keys
              result_hash.merge!({open_enrollment_period: (result_hash[:open_enrollment_period][:min]..result_hash[:open_enrollment_period][:max])})
              result_hash
            end
          end
        end

        rule(:benefit_packages) do
          if key? && value
            benefit_packages_array = value.inject([]) do |hash_array, sb_hash|
              if sb_hash.is_a?(Hash)
                result = BenefitSponsors::Validators::BenefitPackages::BenefitPackageContract.new.call(sb_hash)
                if result&.failure?
                  key.failure(text: 'invalid benefit_package', error: result.errors.to_h)
                else
                  hash_array << result.to_h
                end
              else
                key.failure(text: 'invalid benefit_package. Expected a hash.')
              end
              hash_array
            end
            values.merge!(benefit_packages: benefit_packages_array)
          end
        end
      end
    end
  end
end

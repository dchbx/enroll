# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module Profiles
      # Profile Contract is to validate submitted params while persisting agency profile
      class GeneralAgencyProfileContract < ProfileContract

        params do
          required(:market_kind).filled(:symbol)
          optional(:languages_spoken).maybe(:array)
          optional(:working_hours).maybe(:bool)
          optional(:accept_new_clients).maybe(:bool)

          before(:value_coercer) do |result|
            result_hash = result.to_h
            result_hash[:market_kind] = result_hash[:market_kind]&.to_sym
            result_hash
          end
        end
      end
    end
  end
end

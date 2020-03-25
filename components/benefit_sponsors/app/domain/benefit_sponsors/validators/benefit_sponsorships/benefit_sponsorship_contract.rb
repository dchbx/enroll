# frozen_string_literal: true

module BenefitSponsors
  module Validators
    module BenefitSponsorships
      class BenefitSponsorshipContract < Dry::Validation::Contract

        params do
          required(:_id).filled(Types::Bson)
          required(:hbx_id).filled(:string)
          required(:profile_id).filled(Types::Bson)
          optional(:effective_begin_on).maybe(:date)
          optional(:effective_end_on).maybe(:date)
          optional(:termination_kind).maybe(:string)
          optional(:termination_reason).maybe(:string)
          optional(:predecessor_id).maybe(Types::Bson)
          required(:source_kind).filled(:symbol)
          required(:registered_on).filled(:date)
          required(:is_no_ssn_enabled).filled(:bool)
          optional(:ssn_enabled_on).maybe(:date)
          optional(:ssn_disabled_on).maybe(:date)
          required(:aasm_state).filled(:symbol)
          required(:organization_id).filled(Types::Bson)
          required(:market_kind).filled(:symbol)

          optional(:benefit_applications).array(:hash)
        end

        rule(:benefit_applications).each do |key, value|
          if key? && value
            result = Validators::BenefitApplications::BenefitApplicationContract.new.call(value)
            key.failure(text: "invalid benefit application", error: result.errors.to_h) if result&.failure?
          end
        end
      end
    end
  end
end
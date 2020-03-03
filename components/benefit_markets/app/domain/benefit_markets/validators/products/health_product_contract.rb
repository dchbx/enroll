# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Products
      class HealthProductContract < BenefitMarkets::Validators::Products::ProductContract
        params do
          required(:hios_id).filled(:string)
          required(:hios_base_id).filled(:string)
          optional(:csr_variant_id).maybe(:string)
          optional(:health_plan_kind).maybe(:symbol)
          required(:metal_level_kind).filled(:symbol)
          required(:ehb).filled(:float)
          required(:is_standard_plan).filled(:bool)
          optional(:rx_formulary_url).maybe(:string)
          required(:hsa_eligibility).filled(:bool)
          optional(:provider_directory_url).maybe(:string)
          optional(:network_information).maybe(:string)
        end
      end
    end
  end
end
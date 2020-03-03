# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module Products
      class DentalProductContract < BenefitMarkets::Validators::Products::ProductContract
        params do
          required(:hios_id).filled(:string)
          required(:hios_base_id).filled(:string)
          optional(:csr_variant_id).maybe(:string)
          required(:dental_level).filled(:symbol)
          required(:dental_plan_kind).filled(:symbol)
          required(:ehb).filled(:float)
          required(:is_standard_plan).filled(:bool)
          required(:hsa_eligibility).filled(:bool)
          required(:metal_level_kind).filled(:symbol)
        end
      end
    end
  end
end
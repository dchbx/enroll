# frozen_string_literal: true

module BenefitMarkets
  module Validators
    module BenefitSponsorCatalogs
      class BenefitSponsorCatalogContract < ::BenefitMarkets::Validators::ApplicationContract

        params do
          required(:effective_date).filled(:date)
          required(:effective_period).value(type?: Range)
          required(:open_enrollment_period).value(type?: Range)
          required(:probation_period_kinds).array(:symbol)
          required(:product_packages).value(:array)
          required(:service_area_ids).array(Types::Bson)
        end
      end
    end
  end
end

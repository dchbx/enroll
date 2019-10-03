require File.join(File.dirname(__FILE__), "client_pricing_model_spec_helpers/dc")
require File.join(File.dirname(__FILE__), "client_pricing_model_spec_helpers/cca")

module BenefitSponsors
  class PricingModelSpecHelpers
    const_name = Settings.site.key.upcase
    mod = const_get("BenefitSponsors::ClientPricingModelSpecHelpers::#{const_name}")
    extend mod
  end
end
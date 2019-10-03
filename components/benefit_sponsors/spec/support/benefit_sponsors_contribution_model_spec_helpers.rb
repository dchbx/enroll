require File.join(File.dirname(__FILE__), "client_contribution_model_spec_helpers/cca")
require File.join(File.dirname(__FILE__), "client_contribution_model_spec_helpers/dc")

module BenefitSponsors
  class ContributionModelSpecHelpers
    const_name = Settings.site.key.upcase
    mod = const_get("BenefitSponsors::ClientContributionModelSpecHelpers::#{const_name}")
    extend mod
  end
end
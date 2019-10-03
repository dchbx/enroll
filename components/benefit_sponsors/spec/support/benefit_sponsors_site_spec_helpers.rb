require File.join(File.dirname(__FILE__), "client_site_spec_helpers/dc")
require File.join(File.dirname(__FILE__), "client_site_spec_helpers/cca")

module BenefitSponsors
  class SiteSpecHelpers
    const_name = Settings.site.key.upcase
    mod = const_get("BenefitSponsors::ClientSiteSpecHelpers::#{const_name}")
    extend mod
end
end
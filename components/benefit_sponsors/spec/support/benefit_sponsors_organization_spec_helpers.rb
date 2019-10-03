require File.join(File.dirname(__FILE__), "client_organization_spec_helpers/dc")

module BenefitSponsors
  class OrganizationSpecHelpers
    const_name = Settings.site.key.upcase
    mod = const_get("BenefitSponsors::ClientOrganizationSpecHelpers::#{const_name}")
    extend mod
  end
end
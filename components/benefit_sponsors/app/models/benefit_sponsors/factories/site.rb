module BenefitSponsors
  module Factories
    class Site
      def self.build
        site = BenefitSponsors::Site.new
        profile = BenefitSponsors::Organizations::HbxProfile.new
        office_location = BenefitSponsors::Locations::OfficeLocation.new is_primary: true, phone: BenefitSponsors::Locations::Phone.new, address: BenefitSponsors::Locations::Address.new
        profile.office_locations.push office_location
        site.owner_organization = BenefitSponsors::Organizations::ExemptOrganization.new profiles: [ profile ]
        profile.organization = site.owner_organization
        site
      end

      def self.call(site_key:, byline:, long_name:, short_name:, domain_name:, owner_organization:)
        BenefitSponsors::Site.new site_key: site_key,
          long_name: long_name,
          short_name: short_name,
          byline: byline,
          domain_name: domain_name,
          owner_organization: owner_organization
      end

      def self.validate(site)
        site.valid?
      end
    end
  end
end

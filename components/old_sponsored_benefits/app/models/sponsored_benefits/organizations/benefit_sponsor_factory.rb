# Given a profile class, produce and persist appropriate combinations of associated models under the
# following steps:
#
# Get Site
# Initialize appropriate organization type, associate with Site, set legal_name and other attributes 
# from options (e.g. organization_agency, organization_office_location, organization_dba, organization_entity_kind)
# => GeneralOrganization if fein.present?
# => ExemptOrganization if fein.blank?
# => Initialize BenefitSponsorship with BenefitCatalog association
# Note following rules:
# => Only works if profile.is_benefit_sponsorship_eligible?
# => Only one HbxProfile may exist per Site
# => Only HbxProfile, FehbProfile (Congress), and EmployerProfile and subclasses are eligible for BenefitSponsorship

module SponsoredBenefits
  module Organizations
    class BenefitSponsorFactory

      def initialize(profile, legal_name, fein = nil, options = {})

        @profile = profile
        @legal_name = legal_name
        @fein = fein
      end

    end
  end
end

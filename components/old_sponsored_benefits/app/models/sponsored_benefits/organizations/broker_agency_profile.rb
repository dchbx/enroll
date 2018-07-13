module SponsoredBenefits
  module Organizations
    class BrokerAgencyProfile < Profile

      has_many :plan_design_organizations, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization", inverse_of: :broker_agency_profile
      accepts_nested_attributes_for :plan_design_organizations, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

      # All PlanDesignOrganizations that belong to this BrokerRole/BrokerAgencyProfile
      def employer_leads
      end

      class << self

        def find(id)
          SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner(id).first
        end

        def find_or_initialize_broker_profile(broker_agency)
          org = SponsoredBenefits::Organizations::Organization.find_or_initialize_by(fein: broker_agency.fein)
          unless org.persisted?
            org.hbx_id = broker_agency.hbx_id
            org.legal_name = broker_agency.legal_name
            org.dba = broker_agency.dba
            org.is_active = broker_agency.is_active
            org.office_locations = broker_agency.organization.office_locations
            org.broker_agency_profile = SponsoredBenefits::Organizations::BrokerAgencyProfile.new()
          end
          org
        end

        def assign_employer(broker_agency:, employer:, office_locations:)
          org = find_or_initialize_broker_profile(broker_agency)

          plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner_and_sponsor(broker_agency.id, employer.id)

          if plan_design_organization
            plan_design_organization.has_active_broker_relationship = true
            plan_design_organization.office_locations = office_locations
            plan_design_organization.save!
          else
            org.broker_agency_profile.plan_design_organizations.new().tap do |org|
              org.owner_profile_id = broker_agency._id
              org.sponsor_profile_id = employer._id
              org.office_locations = office_locations
              org.fein = employer.fein
              org.legal_name = employer.legal_name
              org.has_active_broker_relationship = true
              org.sic_code = employer.sic_code
              org.save!
            end
          end
        end

        def unassign_broker(broker_agency:, employer:)
          return if broker_agency.nil?
          plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner_and_sponsor(broker_agency.id, employer.id)
          return unless plan_design_organization.present?
          plan_design_organization.has_active_broker_relationship = false
          plan_design_organization.sic_code ||= employer.sic_code
          plan_design_organization.save!
          plan_design_organization.expire_proposals
        end
      end

    end
  end
end

module BenefitSponsors
  module ClientOrganizationSpecHelpers
    module DC
      def general_organization_properties(site, profile)
        org_id = BSON::ObjectId.new
        legal_name  = "ACME Widgets, Inc."
        dba         = "ACME Co."
        entity_kind = :c_corporation
        fein = Forgery('basic').text(
                 :allow_lower   => false,
                 :allow_upper   => false,
                 :allow_numeric => true,
                 :allow_special => false, :exactly => 9
               )
        org_props = {
          _id: org_id,
          hbx_id: "ALKJVFKLEIJDSLF",
          fein: fein,
          dba: dba,
          entity_kind: entity_kind,
          legal_name: legal_name,
          _type: "BenefitSponsors::Organizations::GeneralOrganization",
          site_id: site.id,
          profiles: [
            profile
          ]
        }
        BenefitSponsors::Organizations::Organization.collection.insert_one(org_props)
        org_id
      end

      def general_agency_profile_properties
        inbox_id = BSON::ObjectId.new
        inbox_access_key = [inbox_id.to_s, SecureRandom.hex(10)].join
        ep_id = BSON::ObjectId.new
        ol_id = BSON::ObjectId.new
        address_id = BSON::ObjectId.new
        phone_id = BSON::ObjectId.new
        o_location_props = {
          _id: ol_id,
          is_primary: true,
          address: {
            _id: address_id,
            kind: "primary",
            address_1: "27 Reo Road",
            address_2: "Apt 1111",
            zip: "20024",
            city: "Washington",
            state: "DC"
          },
          phone:  {
            _id: phone_id,
            kind: "work",
            area_code: "617",
            number: "5551212"
          }
        }
        {
          _id: ep_id,
          is_benefit_sponsorship_eligible: false,
          market_kind: :shop,
          _type: "BenefitSponsors::Organizations::GeneralAgencyProfile",
          contact_method: :paper_and_electronic,
          languages_spoken: [:en],
          working_hours: false,
          aasm_state: "is_applicant",
          documents: [],
          inbox: {
            _id: inbox_id,
            access_key: inbox_access_key,
            messages: []
          },
          office_locations: [
            o_location_props
          ]
        }
      end

      def employer_profile_properties
        inbox_id = BSON::ObjectId.new
        inbox_access_key = [inbox_id.to_s, SecureRandom.hex(10)].join
        ep_id = BSON::ObjectId.new
        ol_id = BSON::ObjectId.new
        address_id = BSON::ObjectId.new
        phone_id = BSON::ObjectId.new
        o_location_props = {
          _id: ol_id,
          is_primary: true,
          address: {
            _id: address_id,
            kind: "primary",
            address_1: "27 Reo Road",
            address_2: "Apt 1111",
            zip: "20024",
            city: "Washington",
            state: "DC"
          },
          phone:  {
            _id: phone_id,
            kind: "work",
            area_code: "617",
            number: "5551212"
          }
        }
        {
          _id: ep_id,
          is_benefit_sponsorship_eligible: true,
          _type: "BenefitSponsors::Organizations::AcaShopDcEmployerProfile",
          contact_method: :paper_and_electronic,
          documents: [],
          inbox: {
            _id: inbox_id,
            access_key: inbox_access_key,
            messages: []
          },
          office_locations: [
            o_location_props
          ]
        }
      end

      def with_aca_shop_employer_profile(site)
        general_organization_properties(site, employer_profile_properties)
      end

      def with_aca_shop_general_agency_profile(site)
        general_organization_properties(site, general_agency_profile_properties)
      end
    end
  end
end
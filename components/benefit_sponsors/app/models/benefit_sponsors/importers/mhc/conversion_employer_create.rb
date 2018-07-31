module BenefitSponsors
  module Importers::Mhc
    class ConversionEmployerCreate < ::Importers::Mhc::ConversionEmployerCreate

      def save
        if valid?
          organization = BenefitSponsors::Organizations::Organization.where(fein: fein).first
          puts "loading conversion employer with legalname --- #{legal_name}" unless Rails.env.test?

          if organization
            #needs helper here
            organization.create_employer_profile(employer_profile_prams)
          else
            new_organization = BenefitSponsors::Organizations::GeneralOrganization.new(form_organizational_params)
            employer_profile = BenefitSponsors::Organizations::AcaShopCcaEmployerProfile.new(employer_profile_prams.merge(:organization => new_organization))
            benefit_sponsorship = employer_profile.add_benefit_sponsorship
            benefit_sponsorship.update_attributes!(registered_on: registered_on, source_kind: :mid_plan_year_conversion)
            set_attestation_to_true(benefit_sponsorship)
          
            save_result = new_organization.save!

            if save_result
              map_poc(employer_profile)

              if broker_npn.present?
                broker_agency_profile = BenefitSponsors::Organizations::Organization.broker_agency_profiles.where(:corporate_npn => broker_npn).first
                new_organization.profiles << broker_agency_profile if broker_agency_profile
              end
            end

            propagate_errors(new_organization.employer_profile)
            return save_result
          end
        end
      end

      def set_attestation_to_true(benefit_sponsorship)
        attestation = benefit_sponsorship.build_employer_attestation
        attestation.submit
        attestation.approve
        attestation.save

        profile = benefit_sponsorship.profile
        attestation = profile.build_employer_attestation
        attestation.submit
        attestation.approve
        attestation.save
      end

      def map_site
        BenefitSponsors::Site.by_site_key(:cca).first if BenefitSponsors::Site.by_site_key(:cca).present?
      end

      def build_mailing_address
        if mailing_location_address_1.present?
          BenefitSponsors::Locations::Address.new(
            :kind => "mailing",
            :address_1 => mailing_location_address_1,
            :address_2 => mailing_location_address_2,
            :city => mailing_location_city,
            :state => mailing_location_state,
            :zip => mailing_location_zip
            )
        end
      end

      def build_primary_address
        BenefitSponsors::Locations::Address.new(
            :kind => "primary",
            :address_1 => primary_location_address_1,
            :address_2 => primary_location_address_2,
            :city =>  primary_location_city,
            :state => primary_location_state,
            :county => primary_location_county,
            :location_state_code => primary_location_county_fips,
            :zip => primary_location_zip
        )
      end

      def build_phone
        BenefitSponsors::Locations::Phone.new({
                                                  :kind => "work",
                                                  :full_phone_number => contact_phone
                                              })
      end

      def map_office_locations
        locations = []
        primary_address = build_primary_address
        mailing_address = build_mailing_address
        locations << BenefitSponsors::Locations::OfficeLocation.new({
                                                                        :is_primary => true,
                                                                        :address => primary_address,
                                                                        :phone => build_phone,
                                                                    })

        if mailing_address.present?
          unless primary_location_address_1 == mailing_location_address_1
            locations << BenefitSponsors::Locations::OfficeLocation.new({
              :is_primary => false,
              :address => mailing_address,
              })
          end
        end
        locations
      end

      def employer_profile_prams
        {
            :sic_code => sic_code,
            :is_benefit_sponsorship_eligible => true,
            :office_locations => map_office_locations
        }
      end

      def form_organizational_params
        {
            :legal_name => legal_name,
            :dba => dba,
            :fein => fein,
            :entity_kind => :s_corporation,
            :site => map_site
        }
      end
    end
  end
end

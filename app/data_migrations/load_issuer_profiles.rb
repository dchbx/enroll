# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class LoadIssuerProfiles < MongoidMigrationTask

  def migrate
    site_key = EnrollRegistry[:enroll_app].setting(:site_key).item.to_s
    data_filename = "#{Rails.root}/db/seedfiles/#{site_key}/issuer_profile_data.rb"
    puts("No issuer profile data exists in #{data_filename}") unless File.exist?(data_filename)
    return unless File.exist?(data_filename)
    require data_filename
    site = BenefitSponsors::Site.all.where(site_key: site_key.to_sym).first

    puts "*" * 80 unless Rails.env.test?
    ISSUER_PROFILE_DATA.each do |issuer_profile|

      fein = issuer_profile[:fein]
      legal_name = issuer_profile[:legal_name]
      abbreviation = issuer_profile[:abbreviation]
      hbx_carrier_id = issuer_profile[:hbx_carrier_id]
      issuer_hios_ids = issuer_profile[:issuer_hios_ids]
      ivl_health = issuer_profile[:ivl_health].present? ? true : false
      ivl_dental = issuer_profile[:ivl_dental].present? ? true : false
      shop_health = issuer_profile[:shop_health].present? ? true : false
      shop_dental = issuer_profile[:shop_dental].present? ? true : false

      exempt_organiation_params = {
        fein: fein,
        site_id: site.id,
        legal_name: legal_name
      }

      exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(:"profiles.hbx_carrier_id" => hbx_carrier_id).first
      new_exempt_organization = if exempt_organization.present?
                                  exempt_organization
                                else
                                  BenefitSponsors::Organizations::ExemptOrganization.new(exempt_organiation_params)
                                end

      issuer_profile = new_exempt_organization.profiles.first
      if issuer_profile.present?
        puts "Carrier #{legal_name} already exists with this hbx_carrier_id #{hbx_carrier_id}." unless Rails.env.test?
      else
        office_location = BenefitSponsors::Locations::OfficeLocation.new(
          is_primary: true,
          address: {kind: "work", address_1: "address_placeholder", address_2: "address_2", city: "City", state: site_key, zip: "10001" },
          phone: {kind: "main", area_code: "111", number: "111-1111"}
        )

        issuer_profile_params = {
          hbx_carrier_id: hbx_carrier_id,
          abbrev: abbreviation,
          ivl_health: ivl_health,
          ivl_dental: ivl_dental,
          shop_health: shop_health,
          shop_dental: shop_dental,
          issuer_hios_ids: issuer_hios_ids,
          office_locations: [office_location]
        }

        new_issuer_profile = BenefitSponsors::Organizations::IssuerProfile.new(issuer_profile_params)

        new_exempt_organization.profiles << new_issuer_profile
        new_exempt_organization.save

        puts "Successfully created #{legal_name} carrier with hbx_carrier_id #{hbx_carrier_id}" unless Rails.env.test?
      end
    end
    puts "*" * 80 unless Rails.env.test?
  end

end
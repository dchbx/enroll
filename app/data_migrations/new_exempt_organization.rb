# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class NewExemptOrganization < MongoidMigrationTask

  def migrate
    fein = ENV["fein"]
    legal_name = ENV["legal_name"]
    abbreviation = ENV["abbreviation"]
    hbx_carrier_id = ENV["hbx_carrier_id"]
    issuer_hios_ids = ENV["issuer_hios_ids"]
    ivl_health = ENV["ivl_health"].present? ? true : false
    ivl_dental = ENV["ivl_dental"].present? ? true : false
    shop_health = ENV["shop_health"].present? ? true : false
    shop_dental = ENV["shop_dental"].present? ? true : false

    message = ""
    message += "fein," if fein.blank?
    message += " legal_name," if legal_name.blank?
    message += " abbreviation," if abbreviation.blank?
    message += " hbx_carrier_id," if hbx_carrier_id.blank?
    message += " issuer_hios_ids" if issuer_hios_ids.blank?

    if message.present?
      puts "*" * 80 unless Rails.env.test?
      message += " cannot be empty."
      puts message
      puts "*" * 80 unless Rails.env.test?
      return
    end

    site_key = "cca"
    site = BenefitSponsors::Site.all.where(site_key: site_key.to_sym).first
    exempt_organiation_params = {
      fein: fein,
      site_id: site.id,
      legal_name: legal_name
    }

    exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(fein: fein).first
    new_exempt_organization = if exempt_organization.present?
                                exempt_organization
                              else
                                BenefitSponsors::Organizations::ExemptOrganization.new(exempt_organiation_params)
                              end

    issuer_profile = new_exempt_organization.profiles.first
    if issuer_profile.present?
      puts "*" * 80 unless Rails.env.test?
      puts "Carrier #{legal_name} already exists with this fein #{fein}." unless Rails.env.test?
      puts "*" * 80 unless Rails.env.test?
    else
      office_location = BenefitSponsors::Locations::OfficeLocation.new(
        is_primary: true,
        address: {kind: "work", address_1: "address_placeholder", address_2: "address_2", city: "City", state: "St", zip: "10001" },
        phone: {kind: "main", area_code: "111", number: "111-1111"}
      )

      issuer_profile_params = {
        hbx_carrier_id: hbx_carrier_id,
        abbrev: abbreviation,
        ivl_health: ivl_health,
        ivl_dental: ivl_dental,
        shop_health: shop_health,
        shop_dental: shop_dental,
        issuer_hios_ids: [issuer_hios_ids],
        office_locations: [office_location]
      }

      new_issuer_profile = BenefitSponsors::Organizations::IssuerProfile.new(issuer_profile_params)

      new_exempt_organization.profiles << new_issuer_profile
      new_exempt_organization.save

      puts "*" * 80 unless Rails.env.test?
      puts "successfully created #{legal_name} carrier." unless Rails.env.test?
      puts "*" * 80 unless Rails.env.test?
    end
  end

end
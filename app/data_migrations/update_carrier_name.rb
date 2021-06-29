# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCarrierName < MongoidMigrationTask
  def migrate
    puts "*" * 80 unless Rails.env.test?
    puts "Updating carrier legal name in old model." unless Rails.env.test?

    abbrev = ENV["abbrev"]

    org = Organization.where("carrier_profile.abbrev" => abbrev).last
    if org.present?
      org.update_attributes(legal_name: ENV["name"])
      puts "Successfully updated carrier legal name in old model -> #{org.legal_name}" unless Rails.env.test?
    else
      puts "Organization with abbrev not found : #{abbrev} in old model" unless Rails.env.test?
    end
    puts "Updating carrier legal name in new model." unless Rails.env.test?

    eo = BenefitSponsors::Organizations::ExemptOrganization.where(:"profiles.abbrev" => abbrev).first
    if eo.present?
      eo.update_attributes(legal_name: ENV["name"]) if eo.present?
      puts "Successfully updated carrier legal name in new model -> #{org.legal_name}" unless Rails.env.test?
    else
      puts "Organization with abbrev not found : #{abbrev} in new model" unless Rails.env.test?
    end

    puts "*" * 80 unless Rails.env.test?
  end
end

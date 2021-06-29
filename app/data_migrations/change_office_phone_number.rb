# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeOfficePhoneNumber < MongoidMigrationTask
  def migrate
    fein = (ENV['fein']).to_s
    full_phone_number = (ENV['full_phone_number']).to_s
    country_code = (ENV['country_code']).to_s

    if Organization.where(fein: fein).size != 1
      puts "no or more employer with given fein" unless Rails.env.test?
      return
    end
    employer = Organization.where(fein: fein).first
    if employer.primary_office_location.nil? || employer.primary_office_location.phone.nil?
      puts "no office location or phone was found with the given organization" unless Rails.env.test?
      return
    end
    phone = employer.primary_office_location.phone
    phone.update_attributes(country_code: country_code)
    phone.full_phone_number = (full_phone_number)
    phone.save
    puts "The full phone number has been set to: #{full_phone_number} with country code: #{country_code}" unless Rails.env.test?
  rescue StandardError => e
    puts e.message unless Rails.env.test?
  end
end
# frozen_string_literal: true

# require File.join(Rails.root, "lib/mongoid_migration_task")

class MappingToCorrectHiosId < MongoidMigrationTask

  def migrate
    hios_id = ENV['hios_id']
    feins = ENV['feins'].split(',')

    feins.each do |fein|

      organization = ::BenefitSponsors::Organizations::Organization.employer_profiles.where(fein: fein).first

      raise "Issue with fein: #{fein}" unless organization.present?

      application = organization.employer_profile.benefit_applications.where(aasm_state: "active").first
      product = application.benefit_sponsor_catalog.product_packages.where(package_kind: "single_product").first.products.where(hios_id: hios_id).first
      product_id = product.id

      health_sponsored_benefit = application.benefit_packages.first.health_sponsored_benefit
      if product.present?
        health_sponsored_benefit.update_attributes!(reference_product_id: product_id)
        puts "Successfully updated Employer's fein:#{fein} with its hios_id:#{hios_id}" unless Rails.env.test?
      else
        raise "Could not find the product with the hios_id:#{hios_id}" unless Rails.env.test?
      end
      ces = organization.employer_profile.census_employees
      ces.each do |ce|
        enrs = begin
          ce.employee_role.person.primary_family.enrollments.select{|en| en.sponsored_benefit == health_sponsored_benefit}
        rescue StandardError
          nil
        end
        if enrs.present?
          enrs.each do |enrollment|
            enrollment.update_attributes!(product_id: product_id)
            puts "Successfully updated #{ce.full_name} enrollment with its hios_id" unless Rails.env.test?
          end
        else
          raise "Census employee: #{ce.full_name} does not have enrollment" unless Rails.env.test?
        end
      end
    rescue StandardError => e
      puts e.message

    end
  end
end

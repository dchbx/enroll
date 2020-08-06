# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdatePredecessorIdOnBp < MongoidMigrationTask
  def migrate
    old_benefit_package_id = ENV['old_benefit_package_id'].to_s
    renewing_benefit_package_id = ENV['renewing_benefit_package_id'].to_s

    old_benefit_package = ::BenefitSponsors::BenefitPackages::BenefitPackage.find(old_benefit_package_id)
    renewing_benefit_package = ::BenefitSponsors::BenefitPackages::BenefitPackage.find(renewing_benefit_package_id)

    if !renewing_benefit_package.benefit_application.predecessor_id.nil? && renewing_benefit_package.predecessor_id.nil?
      renewing_benefit_package.update_attributes!(predecessor_id: old_benefit_package.id)
      puts "Updated the predecessor_id on the Renewing Benefit Package" unless Rails.env.test?
    else
      puts "Predecessor_id has not been updated. Please check the conditions" unless Rails.env.test?
    end
  rescue StandardError => e
    puts e.to_s
  end
end
# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateContributionUnitIdsOnContributionLevels < MongoidMigrationTask

  # rubocop:disable Style/Next
  def migrate
    date = Date.new(2020,7,23)
    BenefitMarkets::BenefitSponsorCatalog.where(:created_at.gte => date).each do |catalog|
      application = catalog.benefit_application
      if application && (application.created_at.to_date < catalog.created_at.to_date)
        next unless application.benefit_sponsor_catalog_id == catalog.id

        application.benefit_packages.each do |benefit_package|
          benefit_package.sponsored_benefits.each do |sponsored_benefit|
            sponsor_contribution = sponsored_benefit.sponsor_contribution
            sponsor_contribution.contribution_levels.each do |contribution_level|
              cu = sponsor_contribution.contribution_model.contribution_units.where(display_name: contribution_level.display_name).first
              raise "contribution_unit not found for benefit_sponsorship.legal_name - contribution_level id - #{contribution_level.id}" unless cu

              next if cu.id == contribution_level.contribution_unit_id

              contribution_level.update_attributes!(contribution_unit_id: cu.id)
              p "Updated #{contribution_level.display_name} contribution_unit_id for #{application.benefit_sponsorship.legal_name}" unless Rails.env.test?
            end
          end
        end
      end
    end
  end
  # rubocop:enable Style/Next
end
# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateMinimumContributionFactorOnContributionUnit < MongoidMigrationTask
  def migrate
    raise 'Please provide benefit market catalog application date' if ENV['benefit_market_catalog_application_date'].blank?
    raise 'Please provide minimum contribution factor' if ENV['min_contribution_factor'].blank?
    date = Date.strptime(ENV['benefit_market_catalog_application_date'], "%m/%d/%Y")
    min_contribution_factor = ENV['min_contribution_factor'].to_i
    sites = BenefitSponsors::Site.by_site_key(Settings.site.key)
    raise "Unable to find site for site key - #{Settings.site.key}" if sites.blank?

    benefit_sponsors_site = sites.first
    benefit_market = benefit_sponsors_site.benefit_markets.where(kind: :aca_shop).first
    benefit_market_catalog = benefit_market.benefit_market_catalogs.by_application_date(date).first

    raise "Unable to fetch benefit market catalog for the given application date - #{date}" unless benefit_market_catalog

    benefit_market_catalog.product_packages.each do |product_package|
      contribution_model = product_package.contribution_model
      contribution_model.contribution_units.each do |contribution_unit|
        prev_factor = contribution_unit.minimum_contribution_factor
        contribution_unit.minimum_contribution_factor = min_contribution_factor
        puts "Updated #{product_package.product_kind} - #{product_package.package_kind} product package's minimum contribution factor for #{contribution_unit.display_name} from #{prev_factor} to #{contribution_unit.minimum_contribution_factor}." unless Rails.env.test?
      end
    end
    benefit_market_catalog.save
  end
end

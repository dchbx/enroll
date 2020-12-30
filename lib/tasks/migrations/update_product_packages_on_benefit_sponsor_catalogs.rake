# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "update_product_packages_on_benefit_sponsor_catalogs")
# This rake task recreate health product packages on benefit sponsor catalogs
# RAILS_ENV=production bundle exec rake migrations:update_product_packages_on_benefit_sponsor_catalogs
namespace :migrations do
  desc "Update product packages on benefit sponsor catalogs"
  UpdateProductPackagesOnBenefitSponsorCatalogs.define_task :update_product_packages_on_benefit_sponsor_catalogs => :environment
end
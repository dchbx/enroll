# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "add_contribution_models_to_product_package")
# This rake task updates minimum contribution factor on contribution units(benefit market's)
# RAILS_ENV=production bundle exec rake migrations:add_contribution_models_to_product_package
namespace :migrations do
  desc "Updates minimum contribution factor on contribution unit - benefit market level."
  AddContributionModelsToProductPackage.define_task :add_contribution_models_to_product_package => :environment
end

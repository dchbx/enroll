# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "update_minimum_contribution_factor_on_contribution_unit")
# This rake task updates minimum contribution factor on contribution units(benefit market's)
# RAILS_ENV=production bundle exec rake migrations:update_minimum_contribution_factor_on_contribution_unit benefit_market_catalog_application_date='01/01/2020' min_contribution_factor='0'
namespace :migrations do
  desc "Updates minimum contribution factor on contribution unit - benefit market level."
  UpdateMinimumContributionFactorOnContributionUnit.define_task :update_minimum_contribution_factor_on_contribution_unit => :environment
end

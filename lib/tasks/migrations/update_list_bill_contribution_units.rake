# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "update_list_bill_contribution_units")
# This rake task updates minimum & default contribution factor on contribution units(benefit market's)
# RAILS_ENV=production bundle exec rake migrations:update_list_bill_contribution_units
namespace :migrations do
  desc "Updates minimum contribution factor on contribution unit - benefit market level."
  UpdateListBillContributionUnits.define_task :update_list_bill_contribution_units => :environment
end
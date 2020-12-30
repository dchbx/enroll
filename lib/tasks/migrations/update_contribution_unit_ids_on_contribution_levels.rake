# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "update_contribution_unit_ids_on_contribution_levels")
# This rake task updates contribution unit ids on contribution levels if there's mismatch
# RAILS_ENV=production bundle exec rake migrations:update_contribution_unit_ids_on_contribution_levels
namespace :migrations do
  desc "Update contribution unit ids on contribution levels if there's a mismatch"
  UpdateContributionUnitIdsOnContributionLevels.define_task :update_contribution_unit_ids_on_contribution_levels => :environment
end

# frozen_string_literal: true

require File.join(Rails.root, "app", "data_migrations", "populate_assigned_contribution_model")
# This rake task updates assigned contribution model on contribution models(benefit sponsor catalog's)
# RAILS_ENV=production bundle exec rake migrations:populate_assigned_contribution_model
namespace :migrations do
  desc "Populate assigned contribution model on product package - benefit sponsor catalog."
  PopulateAssignedContributionModel.define_task :populate_assigned_contribution_model => :environment
end

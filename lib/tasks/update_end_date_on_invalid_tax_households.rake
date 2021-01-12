# frozen_string_literal: true

# To run rake task: RAILS_ENV=production bundle exec rake migrations:update_end_date_on_invalid_tax_households
require File.join(Rails.root, "app", "data_migrations", "update_end_date_on_invalid_tax_households")

namespace :migrations do
  desc "Update end date on tax household if it is before start date"
  UpdateEndDateOnInvalidTaxHouseholds.define_task :update_end_date_on_invalid_tax_households => :environment
end
# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'expire_prior_year_ivl_active_enrollments')
# This rake task is to expire ivl active enrollments that are from prior plan years.
# RAILS_ENV=production bundle exec rake migrations:expire_prior_year_ivl_active_enrollments
namespace :migrations do
  desc 'expire prior year ivl active enrollments'
  ExpirePriorYearIvlActiveEnrollments.define_task :expire_prior_year_ivl_active_enrollments => :environment
end

# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'fix_ed_source_non_curam_cases')
# This migration is to set a field source on EligibilityDetermination
# model to dictate what is the source of this object's creation.

# Currently, system stores the source as 'Admin_Script' when
# ED objects gets created via Create Eligibility or Renewals
# and cannot differentiate if the object got created
# via Create Eligibility or Renewals.

# RAILS_ENV=production bundle exec rake migrations:fix_ed_source_non_curam_cases
namespace :migrations do
  desc 'setting source field for Admin created EligibilityDetermination objects'
  FixEdSourceNonCuramCases.define_task :fix_ed_source_non_curam_cases => :environment
end

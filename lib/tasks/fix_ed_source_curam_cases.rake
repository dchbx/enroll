# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'fix_ed_source_curam_cases')
# This migration is to set a field source on EligibilityDetermination
# model to dictate what is the source of this object's creation.

# RAILS_ENV=production bundle exec rake migrations:fix_ed_source_curam_cases
namespace :migrations do
  desc 'setting source field for Curam created EligibilityDetermination objects'
  FixEdSourceCuramCases.define_task :fix_ed_source_curam_cases => :environment
end

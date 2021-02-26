# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'fix_2020_ivl_benefit_packages')
# This migration is to update csr_eligibility_kind on EligibilityDetermination objects
# to map this to Standard Products/Plans as csr_0 is mapped to 01 variant Products/Plans.

# RAILS_ENV=production bundle exec rake migrations:fix_2020_ivl_benefit_packages
# namespace :migrations do
#  desc 'Creates a new Benefit Package for csr_0 and also Updates Benefit Package for csr_100'
#  Fix2020IvlBenefitPackages.define_task :fix_2020_ivl_benefit_packages => :environment
# end

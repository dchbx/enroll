# frozen_string_literal: true

require File.join(Rails.root, 'app', 'data_migrations', 'fix_csr_eligibility_kinds_for_eds_with_csr_percent_zero')
# This migration is to update csr_eligibility_kind on EligibilityDetermination objects
# to map this to Standard Products/Plans as csr_0 is mapped to 01 variant Products/Plans.

# RAILS_ENV=production bundle exec rake migrations:fix_csr_eligibility_kinds_for_eds_with_csr_percent_zero
namespace :migrations do
  desc 'updating csr_eligibility_kind of EligibilityDetermination objects for cases with 0 percentage CSR'
  FixCsrEligibilityKindsForEdsWithCsrPercentZero.define_task :fix_csr_eligibility_kinds_for_eds_with_csr_percent_zero => :environment
end

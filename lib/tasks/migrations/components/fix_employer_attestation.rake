require File.join(Rails.root, "app", "data_migrations", "components", "fix_employer_attestation")

# This rake task used to update employer attestation across all organization.
# RAILS_ENV=production bundle exec rake migrations:fix_employer_attestation

namespace :migrations do
  desc "change fein of an organization"
  FixEmployerAttestation.define_task :fix_employer_attestation => :environment
end


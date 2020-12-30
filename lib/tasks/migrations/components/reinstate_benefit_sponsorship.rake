require File.join(Rails.root, "components", "benefit_sponsors", "app", "data_migrations", "reinstate_benefit_sponsorship")

# This rake task used to update employer benefit sponsorship aasm state
# RAILS_ENV=production bundle exec rake migrations:reinstate_benefit_sponsorship id='580e5f31082e766296006dd2'

namespace :migrations do
  desc "reinstate benefit sponsorship"
  ReinstateBenefitSponsorship.define_task :reinstate_benefit_sponsorship => :environment
end

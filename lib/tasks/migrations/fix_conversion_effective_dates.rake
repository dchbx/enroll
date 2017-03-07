require File.join(Rails.root, "app", "data_migrations", "fix_incorrect_effective_dates")

namespace :migrations do
  desc "migration to fix effective dates"
  FixIncorrectEffectiveDates.define_task :fix_conversion_effective_dates => :environment
end

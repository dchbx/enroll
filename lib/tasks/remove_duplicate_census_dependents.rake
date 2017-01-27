require File.join(Rails.root, "app", "data_migrations", "remove_duplicate_census_dependents")

namespace :migrations do
  desc "update catastrophic age off mapping"
  RemoveDuplicateCensusDependents.define_task :remove_duplicate_census_dependents => :environment
end
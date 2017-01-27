require File.join(Rails.root, "app", "data_migrations", "update_csr_plan_names")

namespace :migrations do
  desc "update csr plan names"
  UpdateCsrPlanNames.define_task :update_csr_plan_names => :environment
end
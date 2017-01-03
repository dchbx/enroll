require File.join(Rails.root, "app", "data_migrations", "terminate_dentegra_enrollees")

namespace :migrations do
  desc "terminate 2016 dentegra enrollees"
  TerminateDentegraEnrollees.define_task :terminate_dentegra_enrollees => :environment
end
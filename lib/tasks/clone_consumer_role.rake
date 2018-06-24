require File.join(Rails.root, "app", "data_migrations", "clone_consumer_role")
# This rake task is to clone consumer role from person1 to person2
# RAILS_ENV=production bundle exec rake migrations:clone_conusmer_role old_hbx_id=123123123 new_hbx_id=321321321

namespace :migrations do
  desc "clone consumer role for a person"
  CloneConsumerRole.define_task :clone_conusmer_role => :environment
end

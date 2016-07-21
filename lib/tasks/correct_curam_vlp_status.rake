require File.join(Rails.root, "app", "data_migrations", "correct_curam_vlp_status")

namespace :migrations do
  desc "Correct the curam LP state"
  CorrectCuramVlpStatus.define_task :correct_curam_vlp_status => :environment
end 

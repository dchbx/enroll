require File.join(Rails.root, "app", "data_migrations", "correct_decertified_agencies")

#RAILS_ENV=production bundle exec rake migrations:correct_decertified_agencies fein="521698168"

namespace :migrations do
  desc "Correct decertified general agencies"
  CorrectDecertifiedAgency.define_task :correct_decertified_agencies => :environment
end
require File.join(Rails.root, "app", "data_migrations", "change_person_name_suffix")
# This rake task updates the suffix of a person's name using a spreadsheet. 
# RAILS_ENV=production bundle exec rake migrations:change_person_name_suffix

namespace :migrations do
  desc "change_person_name_suffix"
  ChangePersonNameSuffix.define_task :change_person_name_suffix => :environment
end 
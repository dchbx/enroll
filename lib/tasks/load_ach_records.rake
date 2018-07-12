# loading of 2014, 2015 plans using plans.json file.
namespace :seed do
  desc "Load the ACH records"
  task :ach_records => :environment do
    require File.join(Rails.root, "db/seedfiles/ach_records_seed.rb")
  end
end

namespace :seed do
  desc "Create the qualifying life events"
  task :qualifying_life_event_kinds => :environment do
    require File.join(Rails.root, "db/seedfiles/qualifying_life_event_kinds_seed")
  end
end

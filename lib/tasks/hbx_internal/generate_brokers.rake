require "json"

namespace :hbxinternal do
  desc "build hbx internals team db"
  task :generate_brokers => :environment do
    surnames = Rails.root.join('db', 'seedfiles', 'hbxit', 'seed_data', 'surnames.json')
    givennames = Rails.root.join('db', 'seedfiles', 'hbxit', 'seed_data', 'firstnames.json')
  end
end

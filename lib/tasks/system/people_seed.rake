namespace :system do
  desc "Load people"
  task :people_seed => :environment do

    FactoryBot.create_list(:person, 5, :with_family, :with_consumer_role)
    FactoryBot.create_list(:person, 5, :with_family, :with_employee_role)
    FactoryBot.create_list(:person, 5, :with_broker_role)
    FactoryBot.create_list(:person, 5, :with_family, :with_resident_role)

    puts "::: Created consumers, employees, brokers and resident roles :::"
  end
end

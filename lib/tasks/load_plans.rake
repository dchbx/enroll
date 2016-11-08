# loading of 2014, 2015 plans using plans.json file.
namespace :seed do
  UNUSED_DENTEGRA_HIOS_IDS = ["96156DC0020006", "96156DC0020001", "96156DC0020004"] # These plans are not present in master sheet. having these plans is causing comparion page show empty data.
  desc "Load the plan data"
  task :plans => :environment do
    Plan.delete_all
    plan_file = File.open("db/seedfiles/plans.json", "r")
    data = plan_file.read
    plan_file.close
    plan_data = JSON.load(data)
    plan_data.each do |pd|
      Plan.create!(pd) unless UNUSED_DENTEGRA_HIOS_IDS.include?(pd["hios_id"])
    end
  end
end
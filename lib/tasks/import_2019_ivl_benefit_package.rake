require File.join(Rails.root, "app", "data_migrations", "import_2019_ivl_benefit_package")
# This rake task is to create benefit package for 2019
# RAILS_ENV=production bundle exec rake migrations:import_2019_ivl_benefit_package
namespace :migrations do
  desc "create 2019 IVL benefit package"
  Import2019IvlBenefitPackage.define_task :import_2019_ivl_benefit_package => :environment
end
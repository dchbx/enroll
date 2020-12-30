require File.join(Rails.root, "app", "data_migrations", "update_bga_for_identical_benefit_package")
# This rake task is to update benefit group assignment for identical benefit package

# RAILS_ENV=production bundle exec rake migrations:update_bga_for_identical_benefit_package fein='823757154' title='2019-2020 Health Insurance for GRAPH Strategy USA LP (2019)'

namespace :migrations do
  desc "update benefit group assignment for identical benefit package"
  UpdateBgaForIdenticalBenefitPackage.define_task :update_bga_for_identical_benefit_package => :environment
end

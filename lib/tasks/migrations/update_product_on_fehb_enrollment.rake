#RAILS_ENV=production bundle exec rake migrations:update_product_on_fehb_enrollment feins="222222222","111111111"

require File.join(Rails.root, "app", "data_migrations", "update_product_on_fehb_enrollment")
namespace :migrations do
  desc "update_product_on_fehb_enrollment"
  UpdateProductOnFehbEnrollment.define_task :update_product_on_fehb_enrollment => :environment
end
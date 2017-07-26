require File.join(Rails.root, "app", "data_migrations", "update_dental_relationship_benefits")
# This rake task is to update the person relationship kind
# RAILS_ENV=production bundle exec rake migrations:update_person_relationship_kind fein=522270569 plan_year_start_on=05/01/2017 benefit_group_id='58b65575faca1401ac000411' relationship='spouse'
namespace :migrations do
  desc "Changing relationship kind for person record"
  UpdateDentalRelationshipBenefits.define_task :update_dental_relationship_benefits => :environment
end 
require File.join(Rails.root, "app", "data_migrations", "move_domestic_partner_relation_to_immediate_family")
# This rake task is to clean up the existing data and adds coverage household member of domestic partner under correct coverage household
# RAILS_ENV=production bundle exec rake migrations:move_domestic_partner_relation_to_immediate_family family_id=575edd48f1244e7dc000009d
namespace :migrations do
  desc "adding coverage houshold member record under correct coverage household"
  MoveDomesticPartnerRelationToImmediateFamily.define_task :move_domestic_partner_relation_to_immediate_family => :environment
end 
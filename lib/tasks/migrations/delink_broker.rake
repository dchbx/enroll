require File.join(Rails.root, "app", "data_migrations", "delink_broker")
# This rake task is to delink broker
# RAILS_ENV=production bundle exec rake migrations:delink_broker person_hbx_id=19770741 legal_name=Insurance Associates fein=999994789
# RAILS_ENV=production bundle exec rake migrations:delink_broker person_hbx_id="19783302" legal_name="Patrick M. Dunn, Jr" fein=999900000 organization_ids_to_move="57c78189faca1428a100399c","5775835efaca147801000043","57c78177faca1428a1003449","561c0467547265efb2672300","57252e73082e760662000421","5638b90369702d6c416d0000"
# Rake Task for Ticket-17225
# RAILS_ENV=production bundle exec rake migrations:delink_broker person_hbx_id="19774947" legal_name="The Haney Company" fein=999900675 organization_ids_to_move="57252e7d082e760662000b5a","57c78131faca1428a1001ede","57252e77082e7606620006d3"
namespace :migrations do
  desc "Delinking broker"
  DelinkBroker.define_task :delink_broker => :environment
end 

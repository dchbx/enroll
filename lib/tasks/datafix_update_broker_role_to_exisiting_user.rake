# RAILS_ENV=production bundle exec rake datafix:update_broker_role_to_exisiting_user hbx_id=101802
namespace :datafix do
  desc "Datafix : link broker role to the exisiting user"
  task update_broker_role_to_exisiting_user: :environment do
    user = Person.where(hbx_id: ENV['hbx_id']).first.user
    user.roles << 'broker' 
    user.save!
  end
end
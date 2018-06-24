require File.join(Rails.root, "app", "data_migrations", "trigger_shop_notices")
# Run the following - bundle exec rake migrations:generate_notices
# To run rake task: RAILS_ENV=production bundle exec rake notices:trigger_shop_notices recipient_ids="812870991, 61665313, 522241444, 454931569, 274654360" event="initial_employer_ineligibility_notice" action="employer_notice"

namespace :notices do
  desc "Trigger SHOP notices"
  TriggerShopNotices.define_task :trigger_shop_notices => :environment
end

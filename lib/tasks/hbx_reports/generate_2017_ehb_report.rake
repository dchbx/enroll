#Given that a 2017 enrollment exists in EA with the Applied APTC being greater than EHB_Premium of the enrollment, decrease the applied APTC to equal the EHB_premium of the plan.
# example for running Rake Task with custom dates: RAILS_ENV=production bundle exec rake reports:generate_2017_ehb_report
require File.join(Rails.root, "app", "reports", "hbx_reports", "generate_2017_ehb_report")
namespace :reports do
	desc "Updating APTC Amount if Applied APTC Greater than Premium"
	Generate2017EhbReport.define_task :generate_2017_ehb_report => :environment
end

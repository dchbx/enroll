# This rake task used to send employer secure message it expects FEIN as arguments.
#This rake task used to send employee secure message it expects HBX-ID as arguments.

#RAILS_ENV=production bundle exec rake secure_message:disregard_termination_of_coverage_notice_er fein="876456787 555123457" notice_date=11/25/2017
require File.join(Rails.root, "lib/mongoid_migration_task")
require File.join(Rails.root, "app/helpers/config/aca_helper")
require File.join(Rails.root, "app/helpers/config/site_helper")
require File.join(Rails.root, "app/helpers/config/contact_center_helper")
include Config::AcaHelper
include Config::SiteHelper
include Config::ContactCenterHelper

namespace :secure_message do
  desc "The employees of MA 12-1-2017 new groups received a notice in their accounts that their coverage was terminated because no payment was received from their employer."
  task :disregard_termination_of_coverage_notice_er => :environment do |t, args|
  	feins = ENV['fein'].split(' ').uniq

    feins.each do |fein|
      begin
        org = Organization.where(:fein => fein).first
        create_secure_inbox_message_for_employer(org.employer_profile)
      rescue => e
        puts "Unable to find Organization with FEIN #{fein}, due to -- #{e}" unless Rails.env.test?
      end
    end
  end
end

def create_secure_inbox_message_for_employer(employer_profile)
  body = "Your employees should please disregard the notice that they received on #{ENV['notice_date']} stating that their employer was not offering health coverage through the #{aca_state_name} #{site_short_name}. This notice was sent in error. We apologize for any inconvenience this may have caused."+ 
    "<br><br>Your employees have received a correction message clarifying that their employer has completed its open enrollment period and has successfully met all eligibility requirements. It also confirms that the employees plan selection, if any, will go into effect on the coverage effective date shown in your account."+ 
    "<br><br>Thank you for enrolling into employer-sponsored coverage through the #{site_short_name}." + 
    "<br><br>If you have any questions, please call #{contact_center_phone_number} (TTY: #{contact_center_tty_number}), press option 1."
  subject = "Disregard Termination of Coverage Notice"
  message = employer_profile.inbox.messages.build({ subject: subject, body: body, from: "#{aca_state_abbreviation} #{site_short_name}"})
  message.save!
end
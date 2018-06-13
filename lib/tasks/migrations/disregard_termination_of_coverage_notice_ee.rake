# This rake task used to send employer secure message it expects FEIN as arguments.
# This rake task used to send employee secure message it expects HBX-ID as arguments.

# RAILS_ENV=production bundle exec rake secure_message1:disregard_termination_of_coverage_notice_ee hbx_id="3382429 3504641" notice_date=11/25/2017
require File.join(Rails.root, "lib/mongoid_migration_task")
require File.join(Rails.root, "app/helpers/config/aca_helper")
require File.join(Rails.root, "app/helpers/config/site_helper")
require File.join(Rails.root, "app/helpers/config/contact_center_helper")
include Config::AcaHelper
include Config::SiteHelper
include Config::ContactCenterHelper

namespace :secure_message1 do
  desc "The employees of MA 12-1-2017 new groups received a notice in their accounts that their coverage was terminated because no payment was received from their employer."
  task :disregard_termination_of_coverage_notice_ee => :environment do |t, args|
  	hbx_ids = ENV['hbx_id'].split(' ').uniq

    hbx_ids.each do |hbx_id|
      begin
        person = Person.where(:hbx_id => hbx_id).first
        create_secure_inbox_message_for_employee(person)
      rescue => e
        puts "Unable to find employee with hbx_id #{hbx_id}, due to -- #{e}" unless Rails.env.test?
      end
    end
  end
end

def create_secure_inbox_message_for_employee(person)
  body = "Please disregard the notice that you received on #{ENV['notice_date']} stating that your employer was not offering health coverage through the #{aca_state_name} #{site_short_name}. This notice was sent in error. We apologize for any inconvenience this may have caused." +
   "<br><br>Your employer has completed its open enrollment period and has successfully met all eligibility requirements." + 
   "<br><br>Your plan selection, if any, will go into effect on the coverage effective date shown in your account." +
   "<br><br>Thank you for enrolling into employer-sponsored coverage through the #{site_short_name}."+ 
   "<br> <br>If you have any questions, please call #{contact_center_phone_number} (TTY: #{contact_center_tty_number}), press option 1."
  subject = "Disregard Termination of Coverage Notice"
  message = person.inbox.messages.build({ subject: subject, body: body, from: "#{aca_state_abbreviation} #{site_short_name}"})
  message.save!
end

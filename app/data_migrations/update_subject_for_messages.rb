# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateSubjectForMessages < MongoidMigrationTask

  def migrate
    feins = ENV['fein'].split(',').uniq
    feins.each do |fein|

      organization = BenefitSponsors::Organizations::Organization.where(fein: fein).first
      if organization.present?
        incorrect_message = ENV["incorrect_subject"]
        target_messages = organization.employer_profile.inbox.messages.where(subject: /#{incorrect_message}/i)
        if target_messages.present?
          target_messages.each do |msg|
            if (msg.subject).casecmp(incorrect_message) == 0
              msg.update_attributes!(subject: ENV["correct_subject"])
              puts "Subject sucessfully updated" unless Rails.env.test?
            end
          end
        else
          puts "No message was found with given incorrect subject" unless Rails.env.test?
        end
      else
        puts "No organization was found by the given fein" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message

    end
  end
end

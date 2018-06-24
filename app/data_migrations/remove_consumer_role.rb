require File.join(Rails.root, "lib/mongoid_migration_task")
require "csv"

class RemoveConsumerRole < MongoidMigrationTask
  # This script is meant to disassociate a consumer role for a person who is meant
  # to only have a resident role at this point in time since coverall phase 2 has
  # not been released yet. This script will mark all the current enrollments associated
  # with the hbx_id of the person in question being passed in as an environment variable
  # as coverall as well as destroy the consumer role associated with this person (since
  # they never should have had a consumer role to begin with). There is a corresponding
  # action on the Glue side that will mark all of the asociated policies with the hbx enrollments
  # in EA as coverall as well. Neither script on the EA side nor on the Glue side should
  # result in any new events being fired or the triggering of the creation of any new
  # enrollments/policies or EDI flowing out. Their intent is to strictly clean-up the
  # data to represent what should have been always there.

  def migrate
    # create output file to record changes made by this migration
    results = CSV.open("results_of_consumer_role_data_fix.csv", "wb") unless Rails.env.test?
    results << ["hbx_id that is deleting its consumer role"] unless Rails.env.test?
    results << ["19800086"] unless Rails.env.test?

    people = []
    people << Person.where(hbx_id: ENV['p_to_fix_id'].to_s).first

    people.each do |person|
      person.primary_family && person.primary_family.active_household.hbx_enrollments.each do |enrollment|
        begin
          results << ["************************"] unless Rails.env.test?
          results << ["Beginning for hbx enrollment: #{enrollment.hbx_id}"] unless Rails.env.test?
          # first fix any enrollments - mark all individual enrollments as coverall
          if enrollment.kind == "individual"
            results << ["Updating kind to coverall for hbx enrollment #{enrollment.id}"] unless Rails.env.test?
            enrollment.kind = "coverall"

            #need to associate enrollment with the resident role of the person
            enrollment.resident_role = person.resident_role if person.resident_role.present?

            # check for all members on enrollment to remove all consumer roles
            if enrollment.hbx_enrollment_members.size > 1
              enrollment.hbx_enrollment_members.each do |member|
                if member.person.consumer_role.present?
                  results << ["Removing consumer role: #{member.person.consumer_role.id}"] unless Rails.env.test?
                  member.person.consumer_role.destroy
                end
              end
            end
            #need to remove reference to disassociated consumer role
            enrollment.consumer_role_id = nil
            enrollment.save!
          end
        rescue Exception => e
          puts e.backtrace
        end
      end
      # this is necesary for enrollments with a single family member on the enrollment
      person.consumer_role.destroy if person.consumer_role.present?
      results <<  ["removed consumer role for Person: #{person.hbx_id}"] unless Rails.env.test?

      # this is just to show to the developer that the task is running successfully
      puts "removed consumer role for Person: #{person.hbx_id}" unless Rails.env.test?
    end
  end
end
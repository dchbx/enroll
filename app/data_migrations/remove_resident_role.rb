require File.join(Rails.root, "lib/mongoid_migration_task")
require "csv"

class RemoveResidentRole < MongoidMigrationTask

  # this script will remove the resident role from any person who is not in the
  # explicit list of people who should have received the resident role and have a
  # corresponding coverall enrollment. For people not in this group this rake task
  # will remove the resident role and fix any enrollments associated with that person
  # designated as coverall.

  def migrate
    # create output file to record changes made by this migration
    results = CSV.open("results_of_resident_role_data_fix.csv", "wb") unless Rails.env.test?
    results << ["hbx_id's for valid coverall enrollments"] unless Rails.env.test?
    results << ["19921907", "19931367", "19934866", "2482530", "19921423", "19935890", "19965516", "19800086"] unless Rails.env.test?

    correct_assignments = ENV['coverall_ids'].to_s.split(',')
    # using the p_to_fix_id variable to test individual cases before running on the entire system
    if ENV['p_to_fix_id'].nil?
      people = Person.where("resident_role" => {"$exists" => true, "$ne" => nil})
    else
      people = []
      people << Person.where(hbx_id: ENV['p_to_fix_id'].to_s).first
    end

    results << ["The number of people with resident roles at the start of the rake task: #{people.size}"] unless Rails.env.test?

    people.each do |person|
      # exclude the valid coverall enrollments
      unless correct_assignments.include?(person.hbx_id.to_s)
        person.primary_family && person.primary_family.active_household.hbx_enrollments.each do |enrollment|
          begin
            results << ["************************"] unless Rails.env.test?
            results << ["Beginning for hbx enrollment: #{enrollment.hbx_id}"] unless Rails.env.test?
            results << ["person.hbx_id", "pre-existing consumer role", "created new consumer role", "multiple members", "enrollment.hbx_id"] unless Rails.env.test?
            # first fix any enrollments - can only be inividual or coverall kinds
            if enrollment.kind == "coverall" || enrollment.kind == "individual"
              enrollment.kind = "individual"
              # check for all members on enrollment to remove all resident roles
              if enrollment.hbx_enrollment_members.size > 1
                enrollment.hbx_enrollment_members.each do |member|
                  if member.person.consumer_role.present?
                    member.person.resident_role.destroy if member.person.resident_role.present?
                    results << [member.person.hbx_id, "Y", "N", "Y", enrollment.hbx_id] unless Rails.env.test?
                  elsif member.person.resident_role.present?
                      copy_resident_role_to_consumer_role(member.person.resident_role)
                      member.person.resident_role.destroy
                      results << [member.person.hbx_id, "N", "Y", "Y", enrollment.hbx_id] unless Rails.env.test?
                  end
                end
              elsif person.consumer_role.nil?
                copy_resident_role_to_consumer_role(person.resident_role)
                results << [person.hbx_id, "N", "Y", "N", enrollment.hbx_id] unless Rails.env.test?
              end
              results << [person.hbx_id, "Y", "N", "N", enrollment.hbx_id] unless Rails.env.test?
              # need to explicitly reload person object
              person_reload = Person.find(person.id)
              enrollment.consumer_role_id = person_reload.consumer_role.id
              enrollment.resident_role_id = nil
              enrollment.save!
            end
            # avoid unnecessary destroy calls and remove resident role for person with shop enrollments only
            person_reload ||= Person.find(person.id)
            results << [person_reload.hbx_id, "N", "N", "N", enrollment.hbx_id] unless Rails.env.test?
            person_reload.resident_role.destroy if person_reload.resident_role.present?
            puts "removed resident role for Person: #{person.hbx_id}" unless Rails.env.test?
            results << ["End for hbx enrollment: #{enrollment.hbx_id}"] unless Rails.env.test?
            results << ["************************"] unless Rails.env.test?
          rescue Exception => e
            puts e.backtrace
          end
        end
        # in case there are no enrollments for the person
        # conditional checks verify that this is a person that never entered the main block
        person_reload ||= Person.find(person.id)
        if person_reload.resident_role.present? && person_reload.consumer_role.nil?
          copy_resident_role_to_consumer_role(person_reload.resident_role)
        end
        person_reload.resident_role.destroy if person_reload.resident_role.present?
        results << ["people with incorrect resident_role and no enrollments"] unless Rails.env.test?
        results << [person_reload.hbx_id, "N", "N", "N"] unless Rails.env.test?
        puts "removed resident role for Person: #{person.hbx_id}" unless Rails.env.test?
      end
    end
    unless Rails.env.test?
      results << ["remaining people with resident roles after the task is done updating"]
      remaining_people_with_resident_roles = Person.where("resident_role" => {"$exists" => true, "$ne" => nil})
      remaining_people_with_resident_roles.each do |survivor|
        results << [survivor.hbx_id]
      end
    end
  end

  def copy_resident_role_to_consumer_role(r_role)
    c_role = ConsumerRole.new
    c_role.is_applicant = r_role.is_applicant
    c_role.is_active = r_role.is_active
    c_role.bookmark_url = r_role.bookmark_url
    c_role.is_state_resident = r_role.is_state_resident
    c_role.residency_determined_at = r_role.residency_determined_at
    c_role.contact_method = r_role.contact_method
    c_role.language_preference = r_role.language_preference
    c_role.lawful_presence_determination = r_role.lawful_presence_determination
    c_role.documents = r_role.paper_applications
    c_role.person = r_role.person
    c_role.save!
  end

end
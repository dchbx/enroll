require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateCitizenStatus < MongoidMigrationTask
  ACCEPTABLE_STATES = ["us_citizen", "naturalized_citizen", "alien_lawfully_present", "lawful_permanent_resident", "indian_tribe_member"]
  STATES_TO_FIX = %w(not_lawfully_present_in_us
                     non_native_not_lawfully_present_in_us
                     ssn_pass_citizenship_fails_with_SSA)
  def get_people
    Person.where("versions"=>{"$exists"=> true}).or({"consumer_role.lawful_presence_determination.ssa_responses"=>{"$exists"=> true}},
                                                    {"consumer_role.lawful_presence_determination.vlp_responses"=>{"$exists"=> true}})
  end

  def migrate
    people = get_people
    people.each do |person|
      begin
        fix_citizen_status(person) if STATES_TO_FIX.include? lpd(person).citizen_status
      rescue
        $stderr.puts "Issue migrating person: person #{person.id}, HBX id  #{person.hbx_id}"
      end
    end
  end

  def fix_citizen_status(person)
    all_person_versions = person.versions.reverse
    all_person_versions.each do |person_v|
      next if lpd(person).citizen_status == lpd(person_v).citizen_status
      if version_state_reliable?(person_v)
        lpd(person).update_attributes!(:citizen_status => lpd(person_v).citizen_status)
        unless Rails.env.test?
          puts "Person ID: #{person.id} citizen status was changed to #{lpd(person_v).citizen_status}"
        end
      end
    end
  end

  def version_state_reliable?(person_v)
    authority_acceptable?(person_v) && status_acceptable(person_v)
  end

  def authority_acceptable?(person_v)
    !lpd(person_v).vlp_authority.present? || lpd(person_v).vlp_authority == "curam"
  end

  def status_acceptable(person_v)
    ACCEPTABLE_STATES.include? lpd(person_v).citizen_status
  end

  def lpd(person)
    person.consumer_role.lawful_presence_determination
  end
end
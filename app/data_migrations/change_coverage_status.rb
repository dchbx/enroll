require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeCoverageStatus < MongoidMigrationTask
  def migrate
    person_hbx_id = ENV['person_hbx_id']
    status = ENV['status']
    person = Person.where(hbx_id: person_hbx_id).first
    if person.nil?
      puts "No person was found with given hbx_id" unless Rails.env.test?
    elsif (status.to_s == "true" || status.to_s == "false")
      change_applying_coverage(person, to_bool(status))
    else
      puts "Please enter a valid status" unless Rails.env.test?
    end
  end

  private
  def change_applying_coverage(person, status)
    if person.consumer_role.present?
      puts "Changing applying coverage status for person with hbx: #{person.hbx_id}" unless Rails.env.test?
      person.consumer_role.update_attribute(:is_applying_coverage, status)
    else
      puts "No consumer role was found for person with hbx #{person.hbx_id}" unless Rails.env.test?
    end
  end

  def to_bool(bool_string)
    return true if bool_string == "true" || bool_string == true
    return false if bool_string == "false" || bool_string == false
  end
end
require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeBrokerAssignmentDate < MongoidMigrationTask
  def migrate
    hbx_id = ENV['person_hbx_id']
    new_date = Date.strptime(ENV['new_date'].to_s, "%m/%d/%Y")
    person = Person.where(hbx_id:hbx_id)
    if person.size == 0
      puts "No person found with the given hbx_id" unless Rails.env.test?
      return
    else
      primary_family = person.first.primary_family
      if primary_family.present? && primary_family.current_broker_agency.present?
        primary_family.current_broker_agency.update_attributes(start_on: new_date)
        primary_family.save
      else
        puts "Issue with person account" unless Rails.env.test?
      end
    end
  end
end
require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeEmailAddress < MongoidMigrationTask
  def migrate
    hbx_id = ENV['person_hbx_id']
    old_email = ENV['old_email']
    new_email = ENV['new_email']
    person = Person.where(hbx_id:hbx_id).first
    if person.nil?
      puts "No person was found with given hbx_id" unless Rails.env.test?
    else
      email = person.emails.where(address:old_email).first
      if email.nil?
        puts "No email was found with given hbx_id" unless Rails.env.test?
      else
        email.update_attributes(address:new_email)
        puts "update the email of person #{hbx_id} from #{old_email} to #{new_email}" unless Rails.env.test?
      end
    end
  end
end

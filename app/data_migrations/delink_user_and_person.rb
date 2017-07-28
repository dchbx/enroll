require File.join(Rails.root, "lib/mongoid_migration_task")
class DelinkUserAndPerson< MongoidMigrationTask
  def migrate
    hbx_id = ENV['person_hbx_id']
    person = Person.where(hbx_id:hbx_id)
    if person.size == 0
      puts "No person was found by the given fein" unless Rails.env.test?
      return
    elsif person.size > 1
      puts "More than one person was found with the given fein" unless Rails.env.test?
      return
    end
    if person.first.user.nil?
      puts "More than one person was found with the given fein" unless Rails.env.test?
      return
    else
      person.first.unset(:user_id)
      puts "The user account has been delinked from person with hbx_id: #{hbx_id}" unless Rails.env.test?
    end
  end
end
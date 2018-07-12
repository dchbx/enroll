require File.join(Rails.root, "lib/mongoid_migration_task")
class MoveUserAccountBetweenTwoPeopleAccounts < MongoidMigrationTask
  def migrate
    trigger_single_table_inheritance_auto_load_of_child = Document
    hbx_id_1=ENV['hbx_id_1']
    hbx_id_2=ENV['hbx_id_2']
    person1 = Person.where(hbx_id:hbx_id_1).first
    person2 = Person.where(hbx_id:hbx_id_2).first
    if person1.nil?
      puts "No person found with hbx_id #{hbx_id_1}" unless Rails.env.test?
    elsif person2.nil?
      puts "No person found with hbx_id #{hbx_id_1}" unless Rails.env.test?
    else
      user=person1.user
      if user.nil?
        puts "person with hbx_id  #{hbx_id_1} has no user" unless Rails.env.test?
      else
        user_id = person1.user_id
        person1.unset(:user_id)
        person2.set(user_id: user_id)
        puts "move the user account from  #{hbx_id_1} to #{hbx_id_2}" unless Rails.env.test?
      end
    end
  end
end


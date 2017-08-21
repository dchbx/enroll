require File.join(Rails.root, "lib/mongoid_migration_task")
class MoveUserAccountBetweenTwoPeopleAccounts < MongoidMigrationTask
  def migrate
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
        unless person2.user.nil?
          person2.unset(:user_id)
        end
        person2.user=person1.user
        person1.unset(:user_id)
        person1.save
        person2.save
        puts "move the user account from  #{hbx_id_1} to #{hbx_id_2}" unless Rails.env.test?
      end
    end
  end
end


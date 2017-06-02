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
        person2.user=person1.user
        person1.unset(:user)
        person1.save
        person2.save
      end
    end
  end
end


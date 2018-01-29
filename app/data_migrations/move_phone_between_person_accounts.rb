require File.join(Rails.root, "lib/mongoid_migration_task")
class MovePhoneBetweenPersonAccounts< MongoidMigrationTask
  def migrate
    trigger_single_table_inheritance_auto_load_of_child = VlpDocument
    from_hbx_id = ENV['from_hbx_id']
    to_hbx_id = ENV['to_hbx_id']
    phone_id = ENV['phone_id']
    from_person = Person.where(hbx_id:from_hbx_id).first
    to_person = Person.where(hbx_id:to_hbx_id).first
    if from_person.nil?
      puts "No person found with hbx_id #{from_hbx_id}" unless Rails.env.test?
    elsif to_person.nil?
      puts "No person found with hbx_id #{to_hbx_id}" unless Rails.env.test?
    elsif from_person.phones.size == 0
        puts "person with hbx_id  #{from_hbx_id} has no phone number to transfer" unless Rails.env.test?
    else
        from_person.phones.each do |i|
          if i.id.to_s == phone_id
            to_person.phones << i
            to_person.save
            puts "add phone number #{phone_id} to person with hbx_id  #{to_hbx_id}" unless Rails.env.test?
            break
          end
        end
    end
  end
end


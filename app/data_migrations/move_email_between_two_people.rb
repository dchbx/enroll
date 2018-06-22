require File.join(Rails.root, "lib/mongoid_migration_task")

class MoveEmailBetweenTwoPeople< MongoidMigrationTask
  def migrate
    trigger_single_table_inheritance_auto_load_of_child = VlpDocument
    begin
      from_hbx_id = ENV['from_hbx_id']
      to_hbx_id = ENV['to_hbx_id']
      from_person = Person.where(hbx_id:from_hbx_id).first
      to_person = Person.where(hbx_id:to_hbx_id).first
      if from_person.nil?
        puts "No person was found by the given hbx_id: #{from_hbx_id}" unless Rails.env.test?
        return
      elsif to_person.nil?
        puts  "No person was found by the given hbx_id: #{to_hbx_id}" unless Rails.env.test?
        return
      end
      from_person.emails.each do |i|
        to_person.emails << i
      end
      from_person.emails.clear
      from_person.save!
      to_person.save!
      puts "transfer emails from hbx_id: #{from_hbx_id} to hbx_id: #{to_hbx_id}" unless Rails.env.test?
    rescue => e
      puts "#{e}"
    end
  end
end
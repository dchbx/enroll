require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateHbxId< MongoidMigrationTask
  def migrate
    begin
      valid_hbxid = ENV['valid_hbxid']
      invalid_hbxid = ENV['invalid_hbxid']
       
      correct_person = Person.where(hbx_id: invalid_hbxid).first
      wrong_person = Person.where(hbx_id: valid_hbxid).first

      if correct_person.present? && wrong_person.present?
        wrong_person.unset(:hbx_id)
        correct_person.update_attributes!(hbx_id: valid_hbxid)
        puts "person hbx_id updated" unless Rails.env.test?
      else
        puts "person not found" unless Rails.env.test?
      end
    rescue Exception => e
     puts e.message
    end
  end
end
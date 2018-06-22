require File.join(Rails.root, "lib/mongoid_migration_task")

class FixDocumentStatus < MongoidMigrationTask
  def migrate
    hbx_ids = ENV['hbx_ids'].split(',')
    hbx_ids.each do |hbx_id|
      person = Person.where(hbx_id: hbx_id).first
      person.primary_family.update_family_document_status!
      puts "Person with #{hbx_id} updated" unless Rails.env.test?
    end
  end
end
require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdatePersonRelationshipKind < MongoidMigrationTask
  def migrate
    begin
      hbx_id = ENV['hbx_id'].to_s
      person=Person.where(hbx_id: hbx_id).first
      person_relationships=person.person_relationships.where(:kind=>"child")
      person_relationships.each do | person_relation| 
        person_relation.update_attributes(kind: "self", relative_id: person.id)
      end
      puts "Changed person relationship type to self with hbx_id: #{ENV['hbx_id']} " unless Rails.env.test?
    rescue
      puts "Bad Record" unless Rails.env.test?
    end
  end
end
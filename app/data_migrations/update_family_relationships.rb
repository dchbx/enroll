require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateFamilyRelationships < MongoidMigrationTask
  def migrate
    primary_person = Person.where(hbx_id: ENV['primary_hbx']).first
    if primary_person.present?
      self_relation = primary_person.person_relationships.where(:relative_id => primary_person.id).first
      if self_relation.present?
        self_relation.update_attribute("kind" , "self")
      else
        puts "self relation not found"
      end
    else
      puts "primary person with hbx_id #{ENV['primary_hbx']} not found"
    end
  end
end
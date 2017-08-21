require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveIncorrectPersonRelationship < MongoidMigrationTask
  def migrate
    Person.where(hbx_id: ENV["hbx_id"]).first.person_relationships.where(_id: ENV["_id"]).first.destroy!
    puts "Destoyed person relationships" unless Rails.env.test?
  end
end

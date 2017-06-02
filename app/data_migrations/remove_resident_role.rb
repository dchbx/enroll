require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveResidentRole < MongoidMigrationTask
  def migrate
    correct_assignments = ['58b71497f1244e4a42000095', '572a6491f1244e025a00007f',
      '58b9d9da082e7653ea000106', '58e3dc7d50526c33c5000187']
    people = Person.where("resident_role" => {"$exists" => true, "$ne" => nil})
    people.each do |person|
      unless correct_assignments.include?(person.id.to_s)
        person.resident_role.destroy
        puts "removed resident role for Person: #{person.id}" unless Rails.env.test?
      end
    end
  end
end

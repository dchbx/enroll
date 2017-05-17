require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeGender < MongoidMigrationTask
  def migrate
    begin
      hbx_id = (ENV['hbx_id']).to_s
      id = (ENV['id']).to_s
      person_gender = (ENV['gender']).to_s
      Person.where(hbx_id: hbx_id).first.update_attribute(:gender, person_gender)
      CensusEmployee.where(id: id).first.update_attribute(:gender, person_gender)
      puts "Changed Gender of a Person with hbx_id: #{ENV['hbx_id']} to #{person_gender}" unless Rails.env.test?
    rescue
      puts "Bad Person Record" unless Rails.env.test?
    end
  end
end
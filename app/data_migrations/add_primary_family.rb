require File.join(Rails.root, "lib/mongoid_migration_task")

class AddPrimaryFamily < MongoidMigrationTask
  def migrate
    dep_hbx_id = ENV['dep_hbx_id']
    person = Person.where(hbx_id: dep_hbx_id).last
    family = Family.new
    primary_applicant = family.add_family_member(person, is_primary_applicant: true) unless family.find_family_member_by_person(person)
    person.relatives(family.id).each do |related_person|
    	family.add_family_member(related_person)
	end
	family.family_members.map(&:__association_reload_on_person)
	family.save!
    rescue Exception => e
     	puts e.message
    end
end
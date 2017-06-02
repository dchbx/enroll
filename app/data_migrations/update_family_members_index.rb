require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateFamilyMembersIndex < MongoidMigrationTask
  def migrate
    primary_person = Person.where(hbx_id: ENV['primary_hbx']).first
    dependent_person = Person.where(hbx_id: ENV['dependent_hbx']).first
    if primary_person.present? && dependent_person.present?
      family_members = primary_person.primary_family.family_members
      family_members.where(id: ENV['dependent_family_id']).first.unset(:person_id)
      family_members.where(id: ENV['primary_family_id']).first.update_attributes(person_id: primary_person.id, is_primary_applicant: true)
      family_members.where(id: ENV['dependent_family_id']).first.update_attributes(person_id: dependent_person.id, is_primary_applicant: false)
    else
      raise "some error person with hbx_id:#{ENV['primary_hbx']} and hbx_id:#{ENV['dependent_hbx']} not found"
    end
  end
end

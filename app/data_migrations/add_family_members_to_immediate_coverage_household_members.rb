require File.join(Rails.root, "lib/mongoid_migration_task")

class AddFamilyMembersToImmediateCoverageHouseholdMembers < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id']).first

  	raise "Invalid Hbx Id" unless person.present?

    family = person.primary_family
    household = family.active_household.immediate_family_coverage_household
    family_members = family.active_household.immediate_family_coverage_household.family.family_members

    family_members.each do |fam|
      afm = household.add_coverage_household_member(fam)
      afm.save
    end
  end
end
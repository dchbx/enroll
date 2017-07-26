require File.join(Rails.root, "lib/mongoid_migration_task")

class AddFamilyMemberToCoverageHousehold < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id']).first
    if person.blank?
      raise "Invalid Hbx Id"
    else
      family = person.primary_family
      if family.present?
        family_member = person.primary_family.primary_applicant
        if family_member.present?
          family.active_household.add_household_coverage_member(family_member)
          family.save
        else
          raise "No Family Member Found"
        end
      else
        raise "No Family Found"
      end
    end
  end
end
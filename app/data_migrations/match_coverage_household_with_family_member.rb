require File.join(Rails.root, "lib/mongoid_migration_task")

class MatchCoverageHouseholdWithFamilyMember < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['hbx_id'])
    if person.size == 1
      primary_family = person.first.primary_family
      active_family_members = primary_family.family_members.where(is_active: true)
      coverage_household = primary_family.active_household.coverage_households.where(:is_immediate_family => true).first

      coverage_household.coverage_household_members.each do |chm|
        begin
          active_family_members.find(chm.family_member_id)
        rescue => e
          chm.update_attributes(family_member_id: '')
          chm.coverage_household = nil
          chm.save
        end
      end

      active_family_members.each do |fm|
        unless coverage_household.coverage_household_members.where(family_member_id: fm.id).any?
          coverage_household.coverage_household_members.create(family_member_id: fm.id)
        end
      end
    else
      raise "Invalid Hbx Id"
    end
  rescue Exception => e
    puts e.message
  end
end
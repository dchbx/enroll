require File.join(Rails.root, "lib/mongoid_migration_task")
class MoveDomesticPartnerRelationToImmediateFamily < MongoidMigrationTask
  def migrate
    family = Family.where(_id: ENV['family_id'])
    if family.present?
      if family.count > 1 
        puts "Found more than 1 family with same family id #{ENV['family_id']}" 
      else
        family = family.first
        family_member = family.family_members.where(is_active: "true").detect { |a| a.relationship == "domestic_partner"}
        household = family.active_household
        household.remove_family_member(family_member)
        household.add_household_coverage_member(family_member)
        household.save
      end
    end
  end
end

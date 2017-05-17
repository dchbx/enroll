require File.join(Rails.root, "lib/mongoid_migration_task")
class MoveDomesticPartnerRelationToImmediateFamily < MongoidMigrationTask
  def migrate
    Family.all.each do |family|
      begin
        family_member = family.family_members.where(is_active: "true").detect { |a| a.relationship == "domestic_partner"}
        household = family.active_household
        if family_member
          household.add_household_coverage_member(family_member)
          household.save!
          puts "Moved domestic partner relation to immediate family for the primary family of #{family.primary_applicant.person.full_name}" unless Rails.env.test?
        end
      rescue => e
        puts "Bad Record: #{e}"
      end
    end
  end
end

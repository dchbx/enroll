require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveInvalidCoverageHouseholdMember < MongoidMigrationTask
  def migrate
    begin
      person = Person.where(hbx_id: ENV['person_hbx_id'])
      family_member_id = ENV['family_member_id'].to_s
      coverage_household_member_id = ENV['coverage_household_member_id'].to_s
      ch = person.first.primary_family.active_household.coverage_households.where(:is_immediate_family => true).first
      coverage_household_member = ch.coverage_household_members.where(family_member_id: family_member_id).first
      if !coverage_household_member_id.nil? && coverage_household_member.present?
        chm = ch.remove_coverage_household_member(coverage_household_member_id, family_member_id)
        puts "removed invalid coverage household member: #{coverage_household_member_id}" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
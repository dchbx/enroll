require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveCoverageHouseholdMember < MongoidMigrationTask
  def migrate
    begin
      person = Person.where(hbx_id: ENV['person_hbx_id'])
      family_member = FamilyMember.find(ENV['family_member_id'].to_s)
      coverage_household_member_id = ENV['coverage_household_member_id'].to_s
      action = ENV['action'].to_s
      ch = person.first.primary_family.active_household.coverage_households.where(:is_immediate_family => true).first
      if action == "remove_invalid_fm"
        coverage_household_members = []
      else
        coverage_household_members = ch.coverage_household_members.where(family_member_id: family_member.id)
      end
      if person.blank?
        puts "Invalid hbx_id of person"  unless Rails.env.test?
      elsif !coverage_household_member_id.nil? && coverage_household_members.count > 1 && action == "remove_duplicate_chm"
        puts "total coverage household members for the family member(#{family_member.id}) before delete: #{coverage_household_members.count}" unless Rails.env.test?
        chm = ch.remove_coverage_household_member(coverage_household_member_id, family_member.id)
        coverage_household_members = ch.coverage_household_members.where(family_member_id: family_member.id)
        puts "removed duplicate coverage household member: #{coverage_household_member_id}" unless Rails.env.test?
        puts "total coverage household members for the family member(#{family_member.id}) after delete: #{coverage_household_members.count}" unless Rails.env.test?
      elsif action == "remove_fm_from_ch"
        chm = ch.remove_family_member(family_member)
        ch.save
        puts "remove family member from coverage household: #{family_member.id}" unless Rails.env.test?
      elsif action == "remove_invalid_fm"
        ch.coverage_household_members.where(family_member_id: family_member || ENV['family_member_id'].to_s).each do |chm|
          chm.destroy
        end
        ch.save
        puts "Removed Invalid Family Member"  unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end
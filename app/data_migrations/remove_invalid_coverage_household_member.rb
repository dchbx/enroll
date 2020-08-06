# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveInvalidCoverageHouseholdMember < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['person_hbx_id'])
    family_member_id = ENV['family_member_id'].to_s
    coverage_household_member_id = ENV['coverage_household_member_id'].to_s
    action = ENV['action'].to_s
    ch = person.first.primary_family.active_household.coverage_households.where(:is_immediate_family => true).first
    if action == "remove_invalid_chms"
      ch.coverage_household_members.delete_if { |chm| ((chm.family_member_id.present? && !chm.family.family_members.map(&:id).compact.flatten.map(&:to_s).include?(chm.family_member_id.to_s)) || chm.family_member.blank?) }
      puts "Removed invalid coverage household members." unless Rails.env.test?
    else
      coverage_household_member = ch.coverage_household_members.where(family_member_id: family_member_id).first
      chm = ch.remove_coverage_household_member(coverage_household_member_id, family_member_id) if coverage_household_member.present?
      puts "removed invalid coverage household member: #{coverage_household_member_id}" unless Rails.env.test?
    end
  rescue Exception => e
    puts e.message
  end
end
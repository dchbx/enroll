# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class RemoveCoverageHouseHoldMemberForInactiveFamilyMember < MongoidMigrationTask
  def migrate
    #person_hbx_id=19810927 family_member_hbx_id=123123123
    person = Person.where(hbx_id: ENV['person_hbx_id']).first
    if person.blank? && person.primary_family.nil?
      raise "Invalid hbx_id of person / Person doesn't have a family"
    else
      family = person.primary_family
      coverage_household = family.active_household.immediate_family_coverage_household
      coverage_house_hold_members = coverage_household.coverage_household_members
      family_member_ids = coverage_house_hold_members.map(&:family_member_id).map(&:to_s)
      valid_family_members = coverage_household.family.family_members.map(&:id).map(&:to_s)
      chm_to_be_removed = family_member_ids - valid_family_members
      #chm_to_be_added = valid_family_members - family_member_ids
      if chm_to_be_removed.empty?
        puts "No Coverage Household to remove" unless Rails.env.test?
      else
        puts "Removing the following CHM with Family member id #{chm_to_be_removed.join(', ')}" unless Rails.env.test?
        coverage_house_hold_members.where(:family_member_id.in => chm_to_be_removed.map{ |e| e.empty? ? nil : e }).map(&:delete)
        coverage_household.save
      end
    end
  end
end
# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveFamilyMemberFromCoverageHousehold < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['person_hbx_id']).first
    family_member_id = ENV['family_member_id'].to_s
    action = ENV['action']
    if person.blank?
      raise "Invalid hbx_id of person"
    else
      family = person.primary_family
      if family.present?
        case action
        when "RemoveDuplicateMembers"
          first_name = ENV["person_first_name"].try(:split, ",") || []
          last_name = ENV["person_last_name"].try(:split, ",") || []
          raise "First name / Last Name not entered." if first_name.empty? && last_name.empty?
          family_members_to_delete = family.family_members.select {|fm| first_name.map(&:downcase).include?(fm.person.first_name.downcase) && last_name.map(&:downcase).include?(fm.person.last_name.downcase)}
          family_members_to_delete.map(&:destroy)
          family.save
          person.save
        when "RemoveCoverageHouseholdMember"
          family.active_household.family_members.each do |i|
            if i.id.to_s == family_member_id
              i.delete
              family.save
              puts "Remove family member of family_member_id:#{family_member_id} " unless Rails.env == 'test'
              return
            else
              puts "No family member was found with family_member_id:#{family_member_id} " unless Rails.env == 'test'
            end
          end
        else
          puts "Invalid action provided"
        end
      else
        raise "No Family Found"
      end
    end
  end
end
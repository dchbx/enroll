require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveFamilyMemberFromCoverageHousehold < MongoidMigrationTask
  def migrate
    person = Person.where(hbx_id: ENV['person_hbx_id']).first
    family_member_id = ENV['family_member_id'].to_s
    if person.blank?
      raise "Invalid hbx_id of person"
    else
      family = person.primary_family
      if family.present?
          family.active_household.family_members.each do |i|
            if i.id.to_s == family_member_id
              i.delete
              family.save
              puts "Remove family member of family_member_id:#{family_member_id} " unless Rails.env == 'test'
              return
            end
          end
          puts "No family member was found with family_member_id:#{family_member_id} " unless Rails.env == 'test'
      else
        raise "No Family Found"
      end
    end
  end
end
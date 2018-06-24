require File.join(Rails.root, "lib/mongoid_migration_task")

class AddFamilyMemberToCoverageHousehold < MongoidMigrationTask
  def migrate
    dependent_hbx_id = ENV['dependent_hbx_id'].to_s
    primary_hbx_id = ENV['primary_hbx_id'].to_s

    person = Person.by_hbx_id(primary_hbx_id).first rescue nil
    dependent = Person.by_hbx_id(dependent_hbx_id).first rescue nil

    if person.present? && dependent.present?
      if person.primary_family.present?
        primary_family = person.primary_family
        active_family_members = primary_family.family_members.where(person_id: dependent.id).and(is_active: true)

        if active_family_members.count == 1
          family_member = active_family_members.first
          primary_family.active_household.add_household_coverage_member(family_member)
          primary_family.save
          puts "CHM created successfully" unless Rails.env.test?
        else
          puts "No/Duplicate Family Members Found for dependent_hbx_id: #{dependent_hbx_id}" unless Rails.env.test?
        end
      else
        puts "No Primary family for the supplied Primary HBX ID" unless Rails.env.test?
      end
    else
      puts "Person or Dependent not found." unless Rails.env.test?
    end
  end
end
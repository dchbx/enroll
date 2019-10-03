# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateAllGaStaffIsPrmaryTrue < MongoidMigrationTask

  def migrate
    all_ga_staff_roles = Person.exists(general_agency_staff_roles: true).map(&:general_agency_staff_roles).flatten
    all_ga_staff_roles.each do |ga_staff|
      ga_staff.update_attributes!(is_primary: true)
    end
    puts "Updating all general agency staff role's is_primary attribute to true" unless Rails.env.test?
  end
end

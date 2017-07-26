require File.join(Rails.root, "lib/mongoid_migration_task")

class DeactivateEmployerStaffRole < MongoidMigrationTask
  def migrate

    organization = Organization.where(:'employer_profile'.exists => true, fein: ENV['fein']).first
    person= Person.by_hbx_id(ENV['hbx_id']).first

    if organization.present? && person.present?
      poc_found = person.employer_staff_roles.detect{|role| role.employer_profile_id.to_s == organization.employer_profile.id.to_s && !role.is_closed?}
      if poc_found
        Person.deactivate_employer_staff_role(person.id, organization.employer_profile.id)
        puts "Deactivated employer staff role" unless Rails.env.test?
      else
        puts "No employer staff role found" unless Rails.env.test?
      end
    else
      unless Rails.env.test?
        puts "No organization was found by the given fein: #{ENV['fein']}" if organization.blank?
        puts "No person found by the given hbx_id: #{ENV['hbx_id']}" if person.blank?
      end
    end
  end
end

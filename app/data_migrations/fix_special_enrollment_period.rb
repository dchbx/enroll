require File.join(Rails.root, "lib/mongoid_migration_task")

class FixSpecialEnrollmentPeriod < MongoidMigrationTask
  def migrate
    begin
      person = Person.where(hbx_id: ENV['person_hbx_id'])
      family = person.first.primary_family if person.present?
      if family.present?
        invalid_sep = family.special_enrollment_periods.select{|sep| !sep.valid?}
        invalid_sep.each do |sep|
          if sep.errors.keys.include?(:next_poss_effective_date)
            pos_effective_date = person.first.active_employee_roles.map(&:employer_profile).map(&:plan_years).map(&:published_or_renewing_published).flatten.map(&:end_on).max
            sep.update_attributes(:next_poss_effective_date => pos_effective_date)
          end
        end
      end
    rescue Exception => e
      puts e.message
    end
  end
end
require File.join(Rails.root, "lib/mongoid_migration_task")

class PopulateEmployeeRoleOnEnrollments < MongoidMigrationTask

  def migrate
    effective_on = Date.strptime(ENV['effective_on'].to_s, "%m/%d/%Y")

    puts "found #{families(effective_on).count} families" unless Rails.env.test?
    @count = 0
    counter = 0
    families(effective_on).each do |family|
      counter += 1
      if counter % 100 == 0
        puts "processed #{counter} families"
      end
      family.active_household.hbx_enrollments.where(query(effective_on)).each do |enrollment|
        set_employee_role(enrollment, family)
      end
    end
    puts "#{@count} enrollments fixed." unless Rails.env.test?
  end

  def set_employee_role(enrollment, family)
    employer_profile = enrollment.employer_profile
    employee_role = family.primary_applicant.person.active_employee_roles.detect{|role| role.employer_profile_id.to_s == employer_profile.id.to_s }
    if employee_role.present?
      @count += 1
      enrollment.update(employee_role_id: employee_role.id)
    end
  end

  def query(effective_on)
    {
      :effective_on.gte => effective_on,
      :aasm_state.nin => (HbxEnrollment::TERMINATED_STATUSES + ['coverage_canceled', 'shopping']),
      :kind.in => ["employer_sponsored", "employer_sponsored_cobra"],
      :employee_role_id => nil
    }
  end

  def families(effective_on)
    Family.where(:"households.hbx_enrollments" => {:$elemMatch => query(effective_on)})
  end
end

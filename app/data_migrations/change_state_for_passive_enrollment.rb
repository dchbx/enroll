require File.join(Rails.root, "lib/mongoid_migration_task")

class ChangeStateForPassiveEnrollment < MongoidMigrationTask
  def migrate
    Person.all.each do |person|
      begin
        enrollments = person.try(:primary_family).try(:active_household).try(:hbx_enrollments)
        plan_year = person.try(:employee_roles).first.try(:employer_profile).try(:plan_years)
        if plan_year.present?
          plan_year = plan_year.last
          enrollments = enrollments.where(effective_on: (plan_year.start_on..plan_year.end_on)).shop_market
          if enrollments.count > 1
            selected_enrollments = enrollments.enrolled
            if selected_enrollments.size == 1
              renewal_enrollments = enrollments.where(effective_on: selected_enrollments.first.effective_on, aasm_state: "coverage_canceled")
              renewal_correct_enrollments = []
              renewal_enrollments.each do |renewal_enrollment|
                if renewal_enrollment.updated_at.strftime("%m/%d/%Y %I:%M%p") == selected_enrollments.first.updated_at.strftime("%m/%d/%Y %I:%M%p")
                  renewal_correct_enrollments << renewal_enrollment
                end
              end
              if renewal_correct_enrollments.size == 1
                hbx_enrollment =  selected_enrollments.first
                renewal_enrollment = renewal_correct_enrollments.first
                if hbx_enrollment.effective_on == renewal_enrollment.effective_on && hbx_enrollment.coverage_kind != renewal_enrollment.coverage_kind
                  renewal_enrollment.update_attribute(:aasm_state, "coverage_enrolled")
                end
              end
            end
          end
        end
      rescue
      end
    end
  end
end

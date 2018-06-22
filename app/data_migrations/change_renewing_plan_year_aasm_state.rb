require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeRenewingPlanYearAasmState< MongoidMigrationTask

  def migrate
    begin
      organization = Organization.where(fein: ENV['fein']).first
      if organization.present?
        return unless ENV['plan_year_start_on'].present?
        plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")
        plan_year = organization.employer_profile.plan_years.where(:start_on => plan_year_start_on).first
        if plan_year.present?
          if ENV['py_state_to'] == "renewing_draft"
            previous_state = plan_year.aasm_state
            plan_year.update_attributes(aasm_state:"renewing_draft")
            plan_year.workflow_state_transitions << WorkflowStateTransition.new(from_state: previous_state, to_state: plan_year.aasm_state)
            puts "Plan year aasm state changed to #{plan_year.aasm_state}" unless Rails.env.test?
          else
            plan_year.revert_renewal! if plan_year.may_revert_renewal?
            plan_year.withdraw_pending! if plan_year.renewing_publish_pending?
            plan_year.renew_publish! if plan_year.may_renew_publish?
            plan_year.advance_date! if plan_year.may_advance_date?
            plan_year.advance_date! if ENV['py_state_to'] == "renewing_enrolled" && plan_year.is_enrollment_valid? && plan_year.may_advance_date?
            if ENV['py_state_to'] == "renewing_enrolled" && !plan_year.is_enrollment_valid?   # for exception case like buniness requested only(roaster with no ce), updating plan year state to renewing enrolled.
              previous_state = plan_year.aasm_state
              plan_year.update_attributes(aasm_state:"renewing_enrolled")
              plan_year.workflow_state_transitions << WorkflowStateTransition.new(from_state: previous_state, to_state: plan_year.aasm_state)
            end
            puts "Plan year aasm state changed to #{plan_year.aasm_state}" unless Rails.env.test?
          end
        end
      else
        puts "No organization was found by the given fein" unless Rails.env.test?
      end
    rescue Exception => e
      puts e.message
    end
  end
end

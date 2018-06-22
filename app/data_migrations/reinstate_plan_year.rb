require File.join(Rails.root, "lib/mongoid_migration_task")

class ReinstatePlanYear < MongoidMigrationTask

  def migrate

    organizations = Organization.where(fein: ENV['fein'])
    plan_year_start_on = Date.strptime(ENV['plan_year_start_on'].to_s, "%m/%d/%Y")

    if organizations.size != 1
      puts "Found No (or) more than 1 organization with the given fein" unless Rails.env.test?
      return
    end

    plan_year = organizations.first.employer_profile.plan_years.where(start_on: plan_year_start_on).first

    if plan_year.present? && plan_year.may_reinstate_plan_year?
      begin
        @active_py_end_on  = plan_year.end_on
        plan_year.reinstate_plan_year!
        plan_year.expire! if plan_year.may_expire?
        update_benefit_group_assignment(plan_year)
        update_enrollments_for_plan_year(plan_year) if ENV['update_current_enrollment'].present? && ENV['update_current_enrollment']
        puts "plan year starting #{plan_year_start_on} reinstated" unless Rails.env.test?
        renewing_plan_year = organizations.first.employer_profile.plan_years.where(start_on: plan_year_start_on + 1.year).first

        if renewing_plan_year.present? && renewing_plan_year.renewing_canceled?
          @renewing_plan_year_start_on = renewing_plan_year.start_on
          renewing_plan_year_py_state = renewing_plan_year.aasm_state
          renewing_plan_year.update_attributes!(aasm_state:'renewing_draft')
          renewing_plan_year.workflow_state_transitions << WorkflowStateTransition.new(from_state: renewing_plan_year_py_state,to_state: 'renewing_draft')
          puts "renewal plan year aasm state updated to #{renewing_plan_year.aasm_state}" unless Rails.env.test?
          if ENV['renewing_force_publish'].present? && ENV['renewing_force_publish']
            renewing_plan_year.force_publish! if renewing_plan_year.may_force_publish? # to renewing_enrolling
            renewing_plan_year.advance_date! if renewing_plan_year.may_advance_date? # to renewing_enrolled
            renewing_plan_year.activate! if renewing_plan_year.may_activate? # to active state
            puts "plan year starting #{renewing_plan_year.start_on} reinstated" unless Rails.env.test?
            update_benefit_group_assignment(renewing_plan_year)
            update_enrollments_for_plan_year(renewing_plan_year) if ENV['update_renewal_enrollment'].present? && ENV['update_renewal_enrollment']
          end
        end
      rescue Exception => e
        puts "Error: #{e.message}" unless Rails.env.test?
      end
    else
      puts "Unable to reinstate plan year/Plan Year not found." unless Rails.env.test?
    end
  end

  def update_enrollments_for_plan_year(plan_year)

    id_list = plan_year.benefit_groups.map(&:id)
    families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
    enrollments = families.inject([]) do |enrollments, family|
      enrollments += family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).to_a
    end

    enrollments.each do |enrollment|
      if enrollment.coverage_terminated? && enrollment.terminated_on == @active_py_end_on
        py_enrollment_state = enrollment.aasm_state
        enrollment.update_attributes!(terminated_on: nil, termination_submitted_on: nil, aasm_state: "coverage_enrolled")
        puts "enrollment updated #{enrollment.hbx_id}." unless Rails.env.test?
        enrollment.workflow_state_transitions << WorkflowStateTransition.new(from_state: py_enrollment_state,to_state: 'coverage_enrolled')
        enrollment.hbx_enrollment_members.each { |mem| mem.update_attributes!(coverage_end_on: nil)}
        enrollment.expire_coverage! if enrollment.may_expire_coverage?
      elsif enrollment.coverage_canceled? && enrollment.effective_on == @renewing_plan_year_start_on
        py_enrollment_state = enrollment.aasm_state
        if TimeKeeper.date_of_record >= @renewing_plan_year_start_on
          enrollment.update_attributes!(terminated_on: nil, termination_submitted_on: nil, aasm_state: "coverage_enrolled")
          puts "enrollment reinstated #{enrollment.hbx_id}." unless Rails.env.test?
          enrollment.workflow_state_transitions << WorkflowStateTransition.new(from_state: py_enrollment_state,to_state: 'coverage_enrolled')
        else
          enrollment.update_attributes!(terminated_on: nil, termination_submitted_on: nil, aasm_state: "auto_renewing")
          puts "enrollment reinstated #{enrollment.hbx_id}." unless Rails.env.test?
          enrollment.workflow_state_transitions << WorkflowStateTransition.new(from_state: py_enrollment_state,to_state: 'auto_renewing')
        end
      end
    end
  end

  def update_benefit_group_assignment(plan_year)
    bg_ids = plan_year.benefit_groups.map(&:id)
    census_employees = CensusEmployee.where({ :"benefit_group_assignments.benefit_group_id".in => bg_ids })
    census_employees.each do |census_employee|
      census_employee.benefit_group_assignments.where(:benefit_group_id.in => bg_ids).each do |assignment|
        if plan_year.expired?
          assignment.expire_coverage! if assignment.may_expire_coverage?
          assignment.update_attributes(end_on: plan_year.end_on,is_active: false)
          puts "benefit group assignment updated" unless Rails.env.test?
        else
          assignment.select_coverage! if assignment.may_select_coverage?
          assignment.update_attributes(end_on: '', is_active: true)
          puts "benefit group assignment updated" unless Rails.env.test?
        end
      end
    end
  end
end

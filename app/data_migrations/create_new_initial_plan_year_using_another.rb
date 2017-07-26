require File.join(Rails.root, "lib/mongoid_migration_task")

class CreateNewInitialPlanYearUsingAnother < MongoidMigrationTask

  def create_initial_plan_year(organization, old_plan_year, start_on)
    start_date = Date.strptime(start_on, "%m%d%Y")
    new_plan_year = organization.employer_profile.plan_years.build({
                                                                       start_on: start_date,
                                                                       end_on: start_date + 1.year - 1.day,
                                                                       open_enrollment_start_on: start_date - 1.month,
                                                                       open_enrollment_end_on: (start_date - 1.month).beginning_of_month + 9.days,
                                                                       fte_count: old_plan_year.fte_count,
                                                                       pte_count: old_plan_year.pte_count,
                                                                       msp_count: old_plan_year.msp_count,
                                                                       aasm_state: 'draft'
                                                                   })
    new_plan_year.save!

    old_plan_year.benefit_groups.each do |old_benefit_group|
      new_group = clone_benefit_group(old_benefit_group, new_plan_year)
      if new_group.save
        CensusEmployee.by_benefit_group_ids([BSON::ObjectId.from_string(old_benefit_group.id.to_s)]).each do |ce|
          ce.add_benefit_group_assignment(new_group, new_plan_year.start_on)
        end
      else
        message = "Error saving benefit_group: #{new_group.id}, for employer: #{@employer_profile.id}"
        raise PlanYearRenewalFactoryError, message
      end
    end
    new_plan_year
  end

  def clone_benefit_group(active_group, new_plan_year)
    new_plan_year.benefit_groups.build({
                                           title: "#{active_group.title.titleize} New",
                                           effective_on_kind: active_group.effective_on_kind,
                                           terminate_on_kind: active_group.terminate_on_kind,
                                           plan_option_kind: active_group.plan_option_kind,
                                           default: active_group.default,
                                           effective_on_offset: active_group.effective_on_offset,
                                           employer_max_amt_in_cents: active_group.employer_max_amt_in_cents,
                                           relationship_benefits: active_group.relationship_benefits,
                                           reference_plan_id: active_group.reference_plan_id,
                                           elected_plan_ids: active_group.elected_plan_ids,
                                           is_congress: false
                                       })
  end

  def force_publish!(new_plan_year)
    if new_plan_year.may_force_publish? && new_plan_year.application_errors.empty?
      new_plan_year.force_publish!
    else
      new_plan_year.workflow_state_transitions << WorkflowStateTransition.new(
          from_state: new_plan_year.aasm_state,
          to_state: 'enrolling'
      )
      new_plan_year.update_attribute(:aasm_state, 'enrolling')
      new_plan_year.save!
    end
    new_plan_year
  end

  def migrate

    begin
      organizations = Organization.where(fein: ENV['fein'])

      if organizations.size == 0
        raise 'No employer found'
      elsif organizations.size > 1
        raise "More than 1 employers found with given fein #{ENV['fein']}"
      end

      organization = organizations.first

      existing_plan_year = organization.employer_profile.plan_years.where(start_on: DateTime.strptime(ENV['old_py_start_on'], "%m%d%Y")).first

      if existing_plan_year.blank?
        raise "Plan year with start date #{ENV['old_py_start_on']} not found"
      end

      new_plan_year = create_initial_plan_year(organization, existing_plan_year, ENV['new_py_start_on'])

      force_publish!(new_plan_year)

      unless Rails.env.test?
        puts "\nExisting plan year."
        puts existing_plan_year.inspect

        puts "\nNew plan year created."
        puts new_plan_year.inspect

        puts "\n"
      end
    rescue Exception => e
      puts e.message
    end
  end
end


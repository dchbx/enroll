require File.join(Rails.root, "lib/mongoid_migration_task")

class CreateNewInitialPlanYear < MongoidMigrationTask

  def create_initial_plan_year(organization, active_plan_year, end_on)
    start_date = end_on + 1.day
    new_plan_year = organization.employer_profile.plan_years.build({
      start_on: end_on + 1.day,
      end_on: end_on + 1.year,
      open_enrollment_start_on: start_date - 1.month,
      open_enrollment_end_on: Date.new(start_date.year, start_date.month - 1, 10),
      fte_count: active_plan_year.fte_count,
      pte_count: active_plan_year.pte_count,
      msp_count: active_plan_year.msp_count
    })

    new_plan_year.save!

    active_plan_year.benefit_groups.each do |active_group|
      new_group = clone_benefit_group(active_group, new_plan_year)
      if new_group.save
        CensusEmployee.by_benefit_group_ids([BSON::ObjectId.from_string(active_group.id.to_s)]).non_terminated.each do |ce|
          ce.add_benefit_group_assignment(new_group, new_plan_year.start_on)
        end
      else
        message = "Error saving benefit_group: #{new_group.id}, for employer: #{@employer_profile.id}"
        raise PlanYearRenewalFactoryError, message
      end
    end
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

  def migrate
    organizations = Organization.where(fein: ENV['fein'])
    if organizations.size > 1
      raise 'more than 1 employer found with given fein'
    end
    organizations.each do |organization|
      active_plan_year = organization.employer_profile.plan_years.where(start_on: ENV['start_on']).first
      if active_plan_year.blank?
        puts "Active plan year not found"
        next
      end
      end_on = active_plan_year.end_on
      create_initial_plan_year(organization, active_plan_year, end_on)
    end
  end
end


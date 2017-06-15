require File.join(Rails.root, "lib/mongoid_migration_task")

class ForcePublishPlanYear < MongoidMigrationTask
  def migrate
    start_on = Date.strptime((ENV['py_new_start_on']).to_s, "%m/%d/%Y")      
    organizations = Organization.where(fein: ENV['fein'])

    if organizations.size != 1
     puts 'issues with given fein'
     return
    end
    plan_year = organizations.first.employer_profile.plan_years.where(start_on: start_on).first
    begin
      plan_year.workflow_state_transitions << WorkflowStateTransition.new(
          from_state: plan_year.aasm_state,
          to_state: 'enrolling'
      )
      plan_year.update_attribute(:aasm_state, 'enrolling')
      puts "Force publish Employer with(#{ENV['fein']}) " unless Rails.env.test?
    rescue Exception => e
      puts e.message
    end
  end
end

# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class AddPlantoEnrollment < MongoidMigrationTask
  def migrate
    enrollment = HbxEnrollment.find(ENV['enrollment_id'].to_s)
    if enrollment.present?
      new_plan = Plan.find(ENV['plan_id'].to_s)
      if new_plan.present?
        enrollment.plan = (new_plan)
        enrollment.save
        puts "Successfully added plan to enrollment" unless Rails.env.test?
      else
        puts "No Plan was found with ID provided"
      end
    else
      puts "No Enrollment was found with ID provided"
    end
  end
end

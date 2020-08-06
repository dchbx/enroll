# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")
class RemoveCongressCensusEmployee < MongoidMigrationTask
  def migrate
    ce = CensusEmployee.where(id: ENV['census_employee_id']).first
    if ce.present? && ce.employer_profile.active_plan_year.benefit_groups.any?(&:is_congress)
      ce.delete
      puts "Census Employee was successfully removed." unless Rails.env.test?
    elsif ce.blank?
      puts "Unable to find a Census Employee with ID provided." unless Rails.env.test?
    elsif ce.present? && ce.employer_profile.active_plan_year.benefit_groups.none?(&:is_congress)
      puts "Census Employee is not a congress employee." unless Rails.env.test?
    end
  end
end
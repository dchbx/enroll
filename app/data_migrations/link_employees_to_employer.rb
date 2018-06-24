require File.join(Rails.root, "lib/mongoid_migration_task")

class LinkEmployeesToEmployer < MongoidMigrationTask
  def migrate
    census_employees = ENV["ce"].split(",")
    ce = CensusEmployee.where(:id.in => census_employees)
    ce.each do |a|
      if a.present?
        a.link_employee_role!
      else
        raise "No Census Employee found for #{a}"
      end
    end
  end
end
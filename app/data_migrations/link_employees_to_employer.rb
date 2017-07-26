require File.join(Rails.root, "lib/mongoid_migration_task")

class LinkEmployeesToEmployer < MongoidMigrationTask
  def migrate
    ce1 = CensusEmployee.find(ENV['ce1'])
    ce2 = CensusEmployee.find(ENV['ce2'])
    ce3 = CensusEmployee.find(ENV['ce3'])
    ce4 = CensusEmployee.find(ENV['ce4'])
    ce5 = CensusEmployee.find(ENV['ce5'])
    
    arr = [ce1, ce2, ce3, ce4, ce5]
    
    arr.each do |a|
      if a.present?
        a.link_employee_role!
      else
        raise "No Census Employee found for #{a}"
      end
    end
  end
end
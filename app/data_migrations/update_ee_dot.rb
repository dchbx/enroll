require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateEeDot < MongoidMigrationTask
  def migrate
    begin
      id = (ENV['id']).to_s
      ce = CensusEmployee.where(id: id).first

      if ENV['employment_terminated_on'].present?
        employment_terminated_on = Date.strptime(ENV['employment_terminated_on'].to_s, "%m/%d/%Y")
        ce.employment_terminated_on = employment_terminated_on
      end

      if ENV['coverage_terminated_on'].present?
        coverage_terminated_on = Date.strptime(ENV['coverage_terminated_on'].to_s, "%m/%d/%Y")
        ce.coverage_terminated_on = coverage_terminated_on
      end
      ce.save!
      puts "Changed Date of Termination to #{employment_terminated_on} and Coverage Termination to #{coverage_terminated_on}" unless Rails.env.test?
    rescue
      puts "Bad Employee Record" unless Rails.env.test?
    end
  end
end
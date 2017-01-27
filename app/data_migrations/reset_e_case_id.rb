require File.join(Rails.root, "lib/mongoid_migration_task")

class ResetECaseId < MongoidMigrationTask
  def migrate
    family = Person.where(hbx_id: ENV['hbx_id'].to_s).first.primary_family
    if family.present?
      puts "Found family for person with hbx_id #{ENV['hbx_id']}" unless Rails.env.test?
      family.unset(:e_case_id)
      puts "Reset e_case_id for family. Family ready for IC to be re-fired." unless Rails.env.test?
    else
      puts "Unable to find family for hbx_id:#{ENV['hbx_id']}" unless Rails.env == 'test'
    end
  end
end

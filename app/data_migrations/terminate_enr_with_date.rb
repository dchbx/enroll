require File.join(Rails.root, "lib/mongoid_migration_task")

class TerminateEnrWithDate < MongoidMigrationTask
  def migrate
    begin
      enr_hbx_id = (ENV['enr_hbx_id']).to_s
      termination_date = Date.strptime(ENV['termination_date'].to_s, "%m/%d/%Y")
      terminated_on = termination_date.end_of_month

      hbx_enr = HbxEnrollment.by_hbx_id(enr_hbx_id).first

      hbx_enr.terminate_coverage!(terminated_on)
      hbx_enr.update_attributes!(termination_submitted_on: termination_date)

      puts "Terminated the enrollment with id: #{enr_hbx_id}. Status of Enrollment: #{hbx_enr.aasm_state} with termination date: #{hbx_enr.terminated_on} " unless Rails.env.test?
    rescue
      puts "Bad Enrollment" unless Rails.env.test?
    end
  end
end

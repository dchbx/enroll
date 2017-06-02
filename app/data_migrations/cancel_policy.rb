require File.join(Rails.root, "lib/mongoid_migration_task")

class CancelPolicy < MongoidMigrationTask
  def migrate
    begin
      enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s)
      enrollment.first.cancel_coverage! if enrollment.first.may_cancel_coverage?
      puts "Canceled Enrollment policy aasm state" unless Rails.env.test?
    rescue Exception => e
      puts e.message
    end
  end
end
require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveDependentFromEeEnrollment < MongoidMigrationTask
  def migrate
    enrollment_id = ENV["enrollment_id"]
    enrollment_memeber_id = ENV["enrollment_member_id"]
    hbx_enrollment = HbxEnrollment.where(id: enrollment_id).first 
    if hbx_enrollment.nil?
      puts "No hbx_enrollment found with the given id" unless Rails.env.test?
    else
      member=hbx_enrollment.hbx_enrollment_members.where(id:enrollment_memeber_id).first
      if member.nil?
        puts "No enrollment member found with the given id" unless Rails.env.test?
      else
        member.delete
        puts "delete the member with id #{enrollment_memeber_id} from hbx_enrollment #{enrollment_id}" unless Rails.env.test?
      end
    end
  end

end

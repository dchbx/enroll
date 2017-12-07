require File.join(Rails.root, "lib/mongoid_migration_task")

class AddSubscriberToEnrollment < MongoidMigrationTask
  def migrate
    hbx_enrollment = HbxEnrollment.by_hbx_id(ENV['policy_hbx_id'].to_s).first
    if hbx_enrollment.nil?
      puts "no enrollment was found with hbx_id #{ENV['policy_hbx_id']}" unless Rails.env.test?
      return
    end
    hbx_enrollment_member = hbx_enrollment.hbx_enrollment_members.find(ENV['hbx_enrollment_member_id'].to_s)
    if hbx_enrollment_member.nil?
      puts "no enrollment member was found with hbx_id #{ENV['policy_hbx_id']} and member_id #{ENV['hbx_enrollment_member_id']}" unless Rails.env.test?
      return
    end
    if hbx_enrollment.subscriber.present?
      puts "the enrollment with hbx_id #{ENV['policy_hbx_id']} already has a subscriber" unless Rails.env.test?
      return
    end
    hbx_enrollment_member.update_attributes(is_subscriber:true)
    puts "set the member member_id #{ENV['hbx_enrollment_member_id']} as the subscriber for enrollment with hbx_id #{ENV['policy_hbx_id']}" unless Rails.env.test?
  end
end

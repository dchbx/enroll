# RAILS_ENV=production bundle exec rake migrations:change_enrollment_member_applicant_id enrollment_hbx_id=477894 enrollment_member_id=123123123 family_member_id=575ee37750526c5859000084
require File.join(Rails.root, "lib/mongoid_migration_task")
class ChangeEnrollmentMemberApplicantId < MongoidMigrationTask
  def migrate
    begin
      enrollments = HbxEnrollment.by_hbx_id(ENV['enrollment_hbx_id'].to_s)
      if enrollments.count != 1
        puts "found more than one/no enrollment with hbx_id #{ENV['enrollment_hbx_id']}" unless Rails.env.test?
        return
      end
      enrollment = enrollments.first
      enrollment_member = enrollment.hbx_enrollment_members.where(id: ENV['enrollment_member_id'].to_s).first
      if enrollment_member.nil?
        puts "No hbx_enrollment member was found with id #{ENV['enrollment_member_id']}" unless Rails.env.test?
        return
      end
      family_members=enrollment.household.family_members
      family_members.each do |family_member|
        if family_member.id.to_s ==  ENV['family_member_id'].to_s
          enrollment_member.update_attributes(applicant_id: family_member.id)
          puts "applicant id of family member #{ENV['enrollment_member_id']} has been updated to #{family_member.id} " unless Rails.env.test?
          return
        end
      end
      puts "No family member was found with #{ENV['family_member_id']}" unless Rails.env.test?
    rescue => e
      puts "#{e}"
    end
  end
end
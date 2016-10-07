require File.join(Rails.root, "lib/mongoid_migration_task")
class AddHbxEnrollmentMember < MongoidMigrationTask
  def migrate
    enrollment = HbxEnrollment.by_hbx_id(ENV['hbx_id'])
    family_member = FamilyMember.find(ENV['family_member_id'])
    existing_record = enrollment.first.hbx_enrollment_members.detect {|hem| hem.applicant_id == family_member.id}
    if existing_record.present?
      puts "this person is already covered"
      return
    end
    if enrollment.present?
      if enrollment.count > 1
        puts "found more than one enrollment with hbx_id #{ENV['hbx_id']}"
      else
        enrollment_member = HbxEnrollmentMember.new
        enrollment.first.hbx_enrollment_members << enrollment_member
        enrollment_member = enrollment.first.hbx_enrollment_members.last
        enrollment_member.applicant_id = family_member.id
        enrollment_member.is_subscriber = false
        enrollment_member.eligibility_date = enrollment.first.hbx_enrollment_members.first.eligibility_date
        enrollment_member.coverage_start_on = enrollment.first.hbx_enrollment_members.first.coverage_start_on
        enrollment_member.save
      end
    end
  end
end
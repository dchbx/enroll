require File.join(Rails.root, "lib/mongoid_migration_task")
class AddExistingFamilyMemberAsDependentToEnrollment< MongoidMigrationTask
  def migrate
    enrollment_id = ENV["hbx_enrollment_id"]
    applicant_id = ENV["family_member_id"]
    coverage_begin=Date.strptime(ENV["coverage_begin"], '%Y-%m-%d')
    hbx_enrollment= HbxEnrollment.where(id: enrollment_id).first
    if hbx_enrollment.nil?
      puts "No hbx_enrollment found with the given id" unless Rails.env.test?
    else
      enrollment_member = HbxEnrollmentMember.new(applicant_id:applicant_id,
                                                  is_subscriber:false,
                                                  eligibility_date: coverage_begin,
                                                  coverage_start_on: coverage_begin)
      hbx_enrollment.hbx_enrollment_members << enrollment_member
      puts "Add hbx_enrollment_member with applicant_id #{applicant_id} to enrollment #{enrollment_id}" unless Rails.env.test?
    end
  end
end


require File.join(Rails.root, "lib/mongoid_migration_task")
class AddHbxEnrollmentMember < MongoidMigrationTask
  def migrate
    begin
      enrollments = HbxEnrollment.by_hbx_id(ENV['hbx_id'].to_s)
      if enrollments.count != 1
        puts "found more than one/no enrollment with hbx_id #{ENV['hbx_id']}" unless Rails.env.test?
        return
      end
      enrollment = enrollments.first
      family_member = FamilyMember.find(ENV['family_member_id'].to_s)
      existing_record = enrollment.hbx_enrollment_members.detect {|hem| hem.applicant_id == family_member.id}
      if existing_record.present?
        puts "this person is already covered" unless Rails.env.test?
        return
      end
      primary_hem = enrollment.hbx_enrollment_members.where(is_subscriber: true).first
      enrollment_member = HbxEnrollmentMember.new(applicant_id: family_member.id, is_subscriber: false, eligibility_date: primary_hem.eligibility_date, coverage_start_on: primary_hem.coverage_start_on)
      enrollment.hbx_enrollment_members << enrollment_member
      enrollment.save!
      puts "Added coverage to the family member" unless Rails.env.test?
    rescue => e
      puts "#{e}"
    end
  end
end
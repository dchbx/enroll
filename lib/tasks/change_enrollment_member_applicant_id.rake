require File.join(Rails.root, "app", "data_migrations", "change_enrollment_member_applicant_id")
# This rake task adds a new person under covered in the existing enrollment
# RAILS_ENV=production bundle exec rake migrations:change_enrollment_member_applicant_id enrollment_hbx_id=477894 enrollment_member_id=123123123 family_member_id=575ee37750526c5859000084
namespace :migrations do
  desc "ChangeEnrollmentMemberApplicantId"
  ChangeEnrollmentMemberApplicantId.define_task :change_enrollment_member_applicant_id => :environment
end
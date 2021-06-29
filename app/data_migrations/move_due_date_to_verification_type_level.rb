# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class MoveDueDateToVerificationTypeLevel < MongoidMigrationTask
  def migrate
    HbxEnrollment.by_unverified.where({
                                        :special_verification_period.ne => nil,
                                        :is_any_enrollment_member_outstanding => true
                                      }).each do |enrollment|
      family = Family.find(enrollment.family_id)
      family.family_members.each do |f_member|

        enrollment = enrolled_policy(family, f_member)

        next if enrollment.blank?

        person = f_member.person
        role = person.consumer_role
        due_date = notice_date(enrollment)

        person.verification_types.each do |v_type|
          if role.special_verifications.where(verification_type: v_type).present?
            next
          elsif due_date.present?
            # this is the notice sent out date.
            v_type.update_attributes(due_date: due_date, type: "notice")
            puts "special verification created for #{person.full_name} On family of #{family.primary_applicant.person.full_name}" if role.save! && !Rails.env.test?
          end
        end
      rescue Exception => e
        puts "Error In #{family.primary_applicant.person.hbx_id}:  #{e}" unless Rails.env.test?

      end
    end
  end

  def enrolled_policy(family, family_member)
    family.enrollments.verification_needed.where(:"hbx_enrollment_members.applicant_id" => family_member.id).first
  end

  def notice_date(enrollment)
    enrollment.special_verification_period
  end
end

#Rake to run it on production: RAILS_ENV=production bundle exec rake creating_enrollment:update_with_reference_enrollment subscriber_hbx_id="19858750" reference_enrollment_hbx_id="1166378" effective_on="12/1/2018" terminated_on="11/30/2019" aasm_state="coverage_expired"

namespace :creating_enrollment do

  desc "Creating a new enrollment with given reference enrollment details"
  task :update_with_reference_enrollment => :environment do

    people = Person.where(hbx_id: ENV['subscriber_hbx_id'])

    if people.size !=1
      puts "Check hbx_id. Found no (or) more than 1 persons" unless Rails.env.test?
      raise
    end

    begin
      person = people.first
      reference_enrollment = HbxEnrollment.where(hbx_id: ENV['reference_enrollment_hbx_id']).first
      effective_on = Date.strptime(ENV['effective_on'], "%m/%d/%Y")
      terminated_on = Date.strptime(ENV['terminated_on'], "%m/%d/%Y")
      aasm_state = ENV['aasm_state']
      enrollment = HbxEnrollment.new(enrollment_kind: "open_enrollment")
      enrollment.kind = reference_enrollment.kind
      enrollment.sponsored_benefit_package_id = reference_enrollment.sponsored_benefit_package_id
      enrollment.employee_role_id = reference_enrollment.employee_role_id
      enrollment.benefit_group_assignment_id = reference_enrollment.benefit_group_assignment_id
      enrollment.sponsored_benefit_id = reference_enrollment.sponsored_benefit_id
      enrollment.effective_on = effective_on
      enrollment.terminated_on = terminated_on
      enrollment.product_id = reference_enrollment.product.id
      enrollment.coverage_kind = reference_enrollment.coverage_kind
      enrollment.waiver_reason = waiver_reason if reference_enrollment.waiver_reason.present?
      enrollment.family_id = reference_enrollment.family_id
      enrollment.benefit_group_id = reference_enrollment.benefit_group_id,
      enrollment.benefit_sponsorship_id = reference_enrollment.benefit_sponsorship_id,
      enrollment.issuer_profile_id = reference_enrollment.issuer_profile_id,
      enrollment.predecessor_enrollment_id = reference_enrollment.id,
      enrollment.plan_id = reference_enrollment.plan_id
      enrollment.rating_area_id = reference_enrollment.rating_area_id
      enrollment.consumer_role_id = person.consumer_role.id if person.consumer_role.present?

      if aasm_state.blank? || !((["inactive", "renewing_waived"]).include? aasm_state)
        family_members = person.primary_family.active_family_members.select { |fm| Family::IMMEDIATE_FAMILY.include? fm.primary_relationship }
        family_members.each do |fm|
          #this family member is not included in the new enrollment generation
          next if fm.person.hbx_id == "19858752"
          hem = HbxEnrollmentMember.new(applicant_id: fm.id, is_subscriber: fm.is_primary_applicant,
                                        eligibility_date: enrollment.effective_on, coverage_start_on: enrollment.effective_on
                                       )

          enrollment.hbx_enrollment_members << hem
          puts "Added coverage for #{fm.person.full_name}" unless Rails.env.test?
        end
      end

      person.primary_family.active_household.hbx_enrollments << enrollment
      person.primary_family.active_household.save!
      enrollment.update_attributes(aasm_state: aasm_state)
      #silent update without triggering event
      enrollment.workflow_state_transitions.create!(from_state: "shopping", to_state: aasm_state, comment: "manual generation", transition_at: (TimeKeeper.date_of_record - 1.day))

      puts "Created a new shop enrollment(hbx_id: #{enrollment.hbx_id}) with #{aasm_state || "coverage_selected"} state & with #{effective_on} as effective_on date" unless Rails.env.test?
    rescue => e
      puts "#{e}"
    end
  end
end

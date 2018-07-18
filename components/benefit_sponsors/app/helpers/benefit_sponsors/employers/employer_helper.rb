module BenefitSponsors
  module Employers
    module EmployerHelper
      def find_employer_profile
        @organization ||= BenefitSponsors::Organizations::Organization.by_employer_profile(params[:id]).first
        @employer_profile ||= @organization.employer_profile
      end

      def add_employer_staff(first_name, last_name, dob, email, employer_profile)
        person = Person.where(first_name: /^#{first_name}$/i, last_name: /^#{last_name}$/i, dob: dob)

        return false, 'Person count too high, please contact HBX Admin' if person.count > 1
        return false, 'Person does not exist on the HBX Exchange' if person.count == 0

        benefit_sponsor_employer_staff_role = BenefitSponsorsEmployerStaffRole.create(person: person.first, employer_profile_id: employer_profile._id)
        benefit_sponsor_employer_staff_role.save

        return true, person.first
      end

      def staff_for_benefit_sponsors_employer(employer_profile)
        Person.where(:benefit_sponsors_employer_staff_roles => {
            '$elemMatch' => {
                employer_profile_id: employer_profile.id,
                aasm_state: :is_active}
        }).to_a
      end

      def staff_for_benefit_sponsors_employer_including_pending(employer_profile)
        Person.where(:benefit_sponsors_employer_staff_roles => {
            '$elemMatch' => {
                employer_profile_id: employer_profile.id,
                :aasm_state.ne => :is_closed
            }
        })
      end

      def hide_or_show_claim_quote_button(employer_profile)
        return true if employer_profile.published_benefit_application.blank?
        return true if employer_profile.benefit_applications_with_drafts_statuses
        # return true if employer_profile.has_active_state? && employer_profile.published_benefit_application.try(:terminated_on).present? && employer_profile.published_benefit_application.terminated_on > TimeKeeper.date_of_record
        # TODO: Fix has_active_state on BenefitSponsorship ?
        return true if employer_profile.published_benefit_application.try(:terminated_on).present? && employer_profile.published_benefit_application.terminated_on > TimeKeeper.date_of_record
        return false if !employer_profile.benefit_applications_with_drafts_statuses && employer_profile.published_benefit_application.present?
        false
      end

      def deactivate_benefit_sponsors_employer_staff(person_id, employer_profile_id)
        begin
          person = Person.find(person_id)
        rescue
          return false, 'Person not found'
        end
        if role = person.benefit_sponsors_employer_staff_roles.detect {|role| role.employer_profile_id.to_s == employer_profile_id.to_s && !role.is_closed?}
          role.update_attributes!(:aasm_state => :is_closed)
          return true, 'Employee Staff Role is inactive'
        else
          return false, 'No matching employer staff role'
        end
      end

      def display_sic_field_for_employer?
        Settings.aca.employer_has_sic_field
      end

      def employer_attestation_is_enabled?
        Settings.aca.employer_attestation
      end
    end
  end
end
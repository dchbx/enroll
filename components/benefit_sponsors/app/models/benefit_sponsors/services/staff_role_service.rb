module BenefitSponsors
  module Services
    class StaffRoleService

      attr_accessor :profile_id

      def initialize(attrs={})
        @attrs = attrs
        @profile_id = attrs[:profile_id]
      end

      def find_profile(form)
        organization = BenefitSponsors::Organizations::Organization.where("profiles._id" => BSON::ObjectId.from_string(form[:profile_id])).first
        organization.employer_profile if organization.present?
      end

      def add_profile_representative!(form)
        profile = find_profile(form)
        Person.add_employer_staff_role(form[:first_name], form[:last_name], form[:dob], form[:email] , profile)
      end

      def deactivate_profile_representative!(form)
        profile = find_profile(form)
        person_ids =Person.staff_for_employer(profile).map(&:id)
        if person_ids.count == 1 && person_ids.first.to_s == form[:person_id]
          return false, 'Please add another staff role before deleting this role'
        else
          Person.deactivate_employer_staff_role(form[:person_id], form[:profile_id])
        end
      end

      def approve_profile_representative!(form)
        person = Person.find(form[:person_id])
        role = person.employer_staff_roles.detect{|role| role.is_applicant? && role.benefit_sponsor_employer_profile_id.to_s == form[:profile_id]}
        if role && role.approve && role.save!
          return true, 'Role is approved'
        else
          return false, 'Please contact HBX Admin to report this error'
        end

      end

    end
  end
end

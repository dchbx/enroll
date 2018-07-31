module BenefitSponsors
  module Serializers
    class StaffRoleSerializer < ActiveModel::Serializer
      attributes :first_name, :last_name, :email, :dob, :status, :phone, :person_id

      attribute :npn, if: :is_broker_profile?
      attribute :status, if: :is_employer_profile?

      def email
        object.work_email_or_best
      end

      def person_id
        object.id
      end

      def phone
        phone = object.phones.detect { |phone| phone.kind == 'work' }
        phone && phone.to_s
      end

      def status
        state = object.user_id.present? ? " Linked" : " Unlinked"
        (staff_role.aasm_state.to_s).titleize + state
      end

      def dob
        object.dob.to_s
      end

      def is_broker_profile?
        object.broker_role.present?
      end

      def npn
        object.broker_role.npn
      end

      def staff_role
        object.employer_staff_roles.where(
          :"benefit_sponsor_employer_profile_id" => instance_options[:profile_id],
          :"aasm_state".in => ['is_active','is_applicant']
        ).first
      end

      def is_employer_profile?
        instance_options[:profile_type] == "benefit_sponsor" || staff_role.present?
      end

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?
          
        end
        hash
      end
    end
  end
end

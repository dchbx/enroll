module BenefitSponsors
  module Serializers
    class StaffRoleSerializer < ActiveModel::Serializer
      attributes :first_name, :last_name, :email, :dob, :status, :phone, :person_id

      attribute :npn, if: :is_broker_profile?

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
        if @instance_options[:profile_type] == "benefit_sponsor"
          object.employer_staff_roles.detect{|staff_role| staff_role.benefit_sponsor_employer_profile_id.to_s == @instance_options[:profile_id]  &&['is_active','is_applicant'].include?("#{staff_role.aasm_state}")}.aasm_state
        end
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

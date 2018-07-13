module BenefitSponsors
  module Forms
    class BenefitPackageFormPolicy < ApplicationPolicy

      attr_reader :benefit_package_form

      def initialize(current_user, benefit_package_form)
        @user = current_user
        @benefit_package_form = benefit_package_form
      end

      def updateable?
        return false unless user.present?
        return true if (is_broker_for_employer? || is_general_agency_staff_for_employer?)
        return true unless role = user && user.person && user.person.hbx_staff_role
        role.permission.modify_employer
      end

      def is_broker_for_employer?
        broker_role = user.person.broker_role
        return false unless broker_role
        employer = benefit_package_form.service.employer_profile
        return false unless employer
        employer.broker_agency_accounts.any? { |account| account.writing_agent_id == broker_role.id }
      end

      # TODO: FIX ME
      def is_general_agency_staff_for_employer?
        return false
      end
    end
  end
end

# frozen_string_literal: true

module BenefitSponsors
  module Forms
    class BenefitApplicationFormPolicy < ApplicationPolicy

      attr_reader :benefit_application_form

      def initialize(current_user, benefit_application_form)
        @user = current_user
        @benefit_application_form = benefit_application_form
      end

      def updateable?
        return false unless user.present?
        return true if is_broker_for_employer? || is_general_agency_staff_for_employer?
        return true if user.person.employer_staff_roles.any? { |r| r.profile.most_recent_benefit_sponsorship.id.to_s == benefit_application_form.benefit_sponsorship_id }
        return true unless role = user&.person && user.person.hbx_staff_role
        role.permission.modify_employer
      end

      def revert_application?
        return true unless role = user.person&.hbx_staff_role
        role.permission.revert_application
      end

      def is_broker_for_employer?
        broker_role = user.person.broker_role
        return false unless broker_role&.active?
        employer = benefit_application_form.service.benefit_sponsorship.profile
        return false unless employer
        employer.broker_agency_accounts.any? { |account| account.writing_agent_id == broker_role.id }
      end

      # TODO: FIX ME
      def is_general_agency_staff_for_employer?
        false
      end
    end
  end
end

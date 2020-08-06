# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    class OrganizationForms::BrokerManagementForm
      include ActiveModel::Validations
      include Virtus.model

      attribute :employer_profile_id, String
      attribute :broker_agency_profile_id, String
      attribute :broker_role_id, String
      attribute :termination_date, String
      attribute :direct_terminate, Boolean

      def broker_agency_id=(val)
        @broker_agency_profile_id = val
      end

      def self.for_create(attrs)
        new(attrs)
      end

      def save
        persist!
      end

      def persist!
        service.assign_agencies(self)
      end

      def self.for_terminate(attrs)
        attrs.permit! if attrs.is_a?(ActionController::Parameters)
        new(attrs)
      end

      def termination_date=(val)
        @termination_date = Date.strptime(val,"%m/%d/%Y")
        @termination_date
      rescue StandardError
        nil
      end

      def direct_terminate=(val)
        @direct_terminate = true if val.downcase == 'true'
        @direct_terminate = false if val.downcase == 'false'
      rescue StandardError
        nil
      end

      def terminate
        terminate!
      end

      def terminate!
        service.terminate_agencies(self)
      end

      protected

      def self.resolve_service
        BenefitSponsors::Services::BrokerManagementService.new
      end

      def service
        return @service if defined?(@service)
        @service = self.class.resolve_service
      end
    end
  end
end

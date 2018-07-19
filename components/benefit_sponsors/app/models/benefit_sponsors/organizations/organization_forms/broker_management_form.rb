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
        new(attrs)
      end

      def termination_date=(val)
        begin
          @termination_date = Date.strptime(val,"%m/%d/%Y")
          return @termination_date
        rescue
          return nil
        end
      end

      def direct_terminate=(val)
        begin
          @direct_terminate = true if val.downcase == 'true'
          @direct_terminate = false if val.downcase == 'false'
        rescue
          return nil
        end
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
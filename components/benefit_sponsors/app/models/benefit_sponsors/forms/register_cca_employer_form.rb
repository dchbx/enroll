module BenefitSponsors
  module Forms
    class RegisterCcaEmployerForm
      extend  ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      # EmployerProfile
      # BrokerAgencyProfile
      # GeneralProfile

      def initialize(params)
        build if params.blank? 

        self
      end

      # validations
      validates_presence_of :first_name


      # Forms cannot be persisted
      def persisted?
        false
      end

      def save
        if valid?
          persist!
          true
        else
          false
        end
      end

      private

      def build
        BenefitSponsors::Services::NewProfileRegistrationService.build
      end

      def persist!
        BenefitSponsors::Services::NewProfileRegistrationService().store!
      end

    end
  end
end
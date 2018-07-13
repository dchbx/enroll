module BenefitSponsors
  module Organizations
    class OrganizationForms::MessageForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :sender_id, String

      def persisted?
        false
      end
    end
  end
end

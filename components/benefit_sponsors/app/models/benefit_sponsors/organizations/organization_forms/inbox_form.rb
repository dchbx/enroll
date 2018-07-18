module BenefitSponsors
  module Organizations
    class OrganizationForms::InboxForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :access_key, String
      attribute :messages, Array[OrganizationForms::MessageForm]

      def persisted?
        false
      end

      def unread_messages
        [] # TODO
      end
    end
  end
end

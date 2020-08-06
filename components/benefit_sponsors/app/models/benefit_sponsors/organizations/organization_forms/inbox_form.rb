# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    class OrganizationForms::InboxForm
      include Virtus.model
      include ActiveModel::Validations

      attribute :access_key, String
      attribute :messages, Array[OrganizationForms::MessageForm]
      attribute :unread_messages_count, Integer

      def persisted?
        false
      end

      def unread_messages
        # This is a short term hack because the _menu partial needs both the real profile object and this object form
        # Other option would be to implement unread_messsages_count in general agency profile
        OpenStruct.new(count: unread_messages_count)
      end
    end
  end
end

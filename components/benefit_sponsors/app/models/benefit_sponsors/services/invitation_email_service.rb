# frozen_string_literal: true

module BenefitSponsors
  module Services
    class InvitationEmailService

      attr_accessor :broker_role_id, :employer_profile

      def initialize(params = {})
        @broker_role_id = params[:broker_role_id]
        @employer_profile = params[:employer_profile]
      end

      def send_broker_successfully_associated_email
        broker_person = Person.where(:'broker_role._id' => get_bson_id(broker_role_id)).first
        body = "You have been selected as a broker by #{employer_profile.legal_name}"

        message_params = {
          sender_id: employer_profile.try(:id),
          parent_message_id: broker_person.id,
          from: employer_profile.try(:legal_name),
          to: broker_person.try(:full_name),
          body: body,
          subject: 'You have been select as the Broker'
        }

        create_secure_message(message_params, broker_person, :inbox)
      end

      def create_secure_message(message_params, inbox_provider, folder)
        message = Message.new(message_params)
        message.folder = Message::FOLDER_TYPES[folder]
        msg_box = inbox_provider.inbox
        msg_box.post_message(message)
        msg_box.save
      end

      def get_bson_id(id)
        BSON::ObjectId.from_string(id)
      end

    end
  end
end

module BenefitSponsors
  module Services
    class MessageService

      def self.for_show(message, current_user)
        update_message(message) unless current_user.has_hbx_staff_role?
      end

      def self.update_message(message)
        message.update_attributes(message_read: true)
      end

      def self.for_destroy(message)
        message.update_attributes(folder: Message::FOLDER_TYPES[:deleted])
      end
    end
  end
end

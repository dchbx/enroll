# frozen_string_literal: true

# rubocop:disable Style/ClassVars
module Config
  module ContactCenterModelConcern
    extend ActiveSupport::Concern

    included do
      delegate :contact_center_name, :to => :class
      delegate :contact_center_phone_number, :to => :class
      delegate :contact_center_short_number, :to => :class
      delegate :contact_center_tty_number, :to => :class
    end

    class_methods do
      def contact_center_name
        @@contact_center_name ||= EnrollRegistry[:enroll_app].setting(:contact_center_name).item
      end

      def contact_center_phone_number
        @contact_center_phone_number ||= EnrollRegistry[:enroll_app].setting(:health_benefit_exchange_authority_phone_number)&.item
      end

      def contact_center_short_number
        @contact_center_short_number ||= EnrollRegistry[:enroll_app].setting(:health_benefit_exchange_authority_phone_number)&.item
      end

      def contact_center_tty_number
        @contact_center_tty_number ||= Settings.contact_center.tty_number
      end
    end
  end
end

# rubocop:enable Style/ClassVars

# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    class FehbEmployerProfile < BenefitSponsors::Organizations::Profile
      include Mongoid::Document
      include BenefitSponsors::Concerns::EmployerProfileConcern

      field :no_ssn, type: Boolean, default: false
      field :enable_ssn_date, type: DateTime
      field :disable_ssn_date, type: DateTime

      def rating_area
        # FIX this
      end

      def sic_code
        # Fix this
      end

      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, true)
        @is_benefit_sponsorship_eligible = true
        self
      end

      def build_nested_models
        return if inbox.present?
        build_inbox
        welcome_subject = "Welcome to #{Settings.site.short_name}"
        welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s online marketplace where benefit sponsors may select and offer products that meet their member's needs and budget."
        inbox.messages.new(subject: welcome_subject, body: welcome_body, from: Settings.site.short_name, created_at: Time.now.utc) unless inbox.messages.where(body: welcome_body).present?
      end
    end
  end
end

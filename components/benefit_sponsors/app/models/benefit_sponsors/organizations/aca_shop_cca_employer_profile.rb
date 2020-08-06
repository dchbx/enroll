# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    class AcaShopCcaEmployerProfile < BenefitSponsors::Organizations::Profile
      # include Concerns::AcaRatingAreaConfigConcern
      include BenefitSponsors::Concerns::EmployerProfileConcern
      include BenefitSponsors::Concerns::Observable

      field :sic_code,            type: String
      field :referred_by,         type: String
      field :referred_reason,     type: String

      # TODO: use SIC code validation
      validates_presence_of :sic_code

      embeds_one :employer_attestation, class_name: '::EmployerAttestation'

      add_observer BenefitSponsors::Observers::EmployerProfileObserver.new, [:update]
      add_observer BenefitSponsors::Observers::NoticeObserver.new, [:process_employer_profile_events]

      after_update :notify_observers

      REFERRED_KINDS = ['Radio', 'Sign on bus, subway, gas station, etc.', 'Online advertisement, such as on Google or Pandora', 'Billboard', 'Video on a website', 'Social media, such as Facebook', 'Online search (for example, searching through Google for places to get insurance)', 'Insurance broker', 'Health insurance company/carrier', 'Hospital or community health center', 'Health insurance Assister or Navigator', 'State or Government Agency (Main Streets or Small Business Administration) ', 'Employer Association', 'Chamber of Commerce', 'Friend or family member', 'Health Connector sponsored event', 'New England Benefits Association (NEBA)', 'Greater Boston Chamber of Commerce', 'Television', 'Newspaper', 'Other'].freeze

      # TODO: Temporary fix until we move employer_attestation to benefit_sponsorship
      def is_attestation_eligible?
        return true unless enforce_employer_attestation?
        employer_attestation.present? && employer_attestation.is_eligible?
      end

      def referred_options
        REFERRED_KINDS
      end

      private

      def initialize_profile
        if is_benefit_sponsorship_eligible.blank?
          write_attribute(:is_benefit_sponsorship_eligible, true)
          @is_benefit_sponsorship_eligible = true
        end

        self
      end

      def build_nested_models
        return if inbox.present?
        build_inbox
        #TODO: After migration uncomment the lines below to get Welcome message for Initial Inbox creation
        # welcome_subject = "Welcome to #{Settings.site.short_name}"
        # welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s online marketplace where benefit sponsors may select and offer products that meet their member's needs and budget."
        # inbox.messages.new(subject: welcome_subject, body: welcome_body)
      end

    end
  end
end

module BenefitSponsors
  module Organizations
    class AcaShopCcaEmployerProfile < BenefitSponsors::Organizations::Profile
      # include Concerns::AcaRatingAreaConfigConcern
      include BenefitSponsors::Concerns::EmployerProfileConcern
      include BenefitSponsors::Concerns::Observable

      field :sic_code,  type: String

      # TODO use SIC code validation
      validates_presence_of :sic_code

      embeds_one  :employer_attestation

      add_observer BenefitSponsors::Observers::EmployerProfileObserver.new

      after_update :notify_observers

      # TODO: Temporary fix until we move employer_attestation to benefit_sponsorship
      def is_attestation_eligible?
        return true unless enforce_employer_attestation?
        employer_attestation.present? && employer_attestation.is_eligible?
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

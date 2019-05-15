module BenefitSponsors
  module Organizations
    class FehbEmployerProfile < BenefitSponsors::Organizations::Profile
      include Mongoid::Document
      include BenefitSponsors::Concerns::EmployerProfileConcern

      field :no_ssn, type: Boolean, default: false
      field :enable_ssn_date, type: DateTime
      field :disable_ssn_date, type: DateTime

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
        unless inbox.messages.where(subject: welcome_subject).present?
          inbox.messages.new(subject: welcome_subject, body: welcome_body)
        end
      end
    end
  end
end

# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    class AcaShopDcEmployerProfile < BenefitSponsors::Organizations::Profile
      # include BenefitSponsors::Employers::EmployerHelper
      include BenefitSponsors::Concerns::EmployerProfileConcern
      include BenefitSponsors::Concerns::Observable

      add_observer BenefitSponsors::Observers::EmployerProfileObserver.new, [:update]
      add_observer BenefitSponsors::Observers::NoticeObserver.new, [:process_employer_profile_events]

      after_update :notify_observers

      def rating_area
        # FIX this
      end

      def sic_code
        # Fix this
      end

      # def census_employees
      #   CensusEmployee.find_by_employer_profile(self)
      # end

      private

      def site
        return @site if defined? @site
        @site = BenefitSponsors::Site.by_site_key(:dc).first
      end

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
        welcome_subject = "Welcome to #{Settings.site.short_name}"
        welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s online marketplace where benefit sponsors may select and offer products that meet their member's needs and budget."
        inbox.messages.new(subject: welcome_subject, body: welcome_body, from: Settings.site.short_name, created_at: Time.now.utc) unless inbox.messages.where(body: welcome_body).present?
      end
    end
  end
end

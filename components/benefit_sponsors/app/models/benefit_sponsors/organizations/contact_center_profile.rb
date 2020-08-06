# frozen_string_literal: true

module BenefitSponsors
  module Organizations
    class ContactCenterProfile
      include Mongoid::Document
      include Mongoid::Timestamps



      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, false)
        @is_benefit_sponsorship_eligible = false
        self
      end

    end
  end
end

module BenefitSponsors
  module Organizations
    class FehbEmployerProfile < BenefitSponsors::Organizations::Profile
      include Mongoid::Document

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


    end
  end
end

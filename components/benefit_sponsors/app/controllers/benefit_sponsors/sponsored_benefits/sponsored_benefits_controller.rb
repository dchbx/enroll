module BenefitSponsors
  module SponsoredBenefits
    class SponsoredBenefitsController < ApplicationController

      before_action :find_benefit_application, :find_employer

      def new
        @sponsored_benefit = BenefitSponsors::Forms::SponsoredBenefit.new(benefit_application, product_package)
      end
    
      private

      def find_benefit_application
      end

      def find_employer
      end
    end
  end
end

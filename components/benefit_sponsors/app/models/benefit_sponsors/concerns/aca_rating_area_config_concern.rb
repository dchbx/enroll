require 'active_support/concern'

module BenefitSponsors
  module Concerns::AcaRatingAreaConfigConcern
    extend ActiveSupport::Concern

    included do
      delegate :market_rating_areas, to: :class
      delegate :use_simple_employer_calculation_model?, to: :class
    end

    class_methods do
      def market_rating_areas
        @@market_rating_areas ||= Settings.aca.rating_areas
      end

      def use_simple_employer_calculation_model?
        @@use_simple_employer_calculation_model ||= (Settings.aca.use_simple_employer_calculation_model.to_s.downcase == "true")
      end
    end
  end
end

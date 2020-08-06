# frozen_string_literal: true

module BenefitMarkets
  class MarketPolicies::Rule

    attr_reader :errors

    def initialize(_policy)
      @errors = []
    end

    def is_satisfied?; end



  end
end

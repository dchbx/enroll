# frozen_string_literal: true

module Config
  module AcaIndividualMarketHelper
    def verification_sensitive_attributes
      ::EnrollRegistry[:verification_sensitive_attributes].setting(:demographic_attributes).item
    end
  end
end
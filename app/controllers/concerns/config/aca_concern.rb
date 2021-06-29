# frozen_string_literal: true

module Config
  module AcaConcern
    def aca_qle_period
      EnrollRegistry[:qle_within_sixty_days].settings(:days).item
    end

    def aca_state_abbreviation
      EnrollRegistry[:enroll_app].setting(:state_abbreviation).item
    end

    def aca_shop_market_cobra_enrollment_period_in_months
      EnrollRegistry[:cobra_enrollment_period].setting(:months).item
    end

    def individual_market_is_enabled?
      return if EnrollRegistry.feature_enabled?(:aca_individual_market)
      flash[:error] = "This Exchange does not support an individual marketplace"
      redirect_to root_path
    end

    def fehb_market_is_enabled?
      @fehb_market_is_enabled ||= EnrollRegistry.feature_enabled?(:fehb_market)
    end

    def general_agency_is_enabled?
      EnrollRegistry.feature_enabled?(:general_agency)
    end

    def redirect_unless_general_agency_is_enabled?
      return if EnrollRegistry.feature_enabled?(:general_agency)
      flash[:error] = "General Agencies are not supported by this Exchange"
      redirect_to broker_agencies_profile_path(@broker_agency_profile)
    end
  end
end

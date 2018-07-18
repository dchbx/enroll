module Config::AcaModelConcern
  extend ActiveSupport::Concern

  included do
    delegate :aca_state_name, to: :class
    delegate :aca_state_abbreviation, to: :class
    delegate :aca_shop_market_cobra_enrollment_period_in_months, to: :class
    delegate :aca_shop_market_employer_family_contribution_percent_minimum, to: :class
    delegate :aca_shop_market_employer_contribution_percent_minimum, to: :class
    delegate :individual_market_is_enabled?, to: :class
    delegate :general_agency_enabled?, to: :class
    delegate :use_simple_employer_calculation_model?, to: :class
    delegate :market_rating_areas, to: :class
    delegate :multiple_market_rating_areas?, to: :class
    delegate :constrain_service_areas?, to: :class
    delegate :transmit_employers_immediately?, to: :class
    delegate :enforce_employer_attestation?, to: :class
    delegate :employer_attestation_is_enabled?, to: :class
    delegate :employee_participation_ratio_minimum, to: :class
    delegate :non_owner_participation_count_minimum, to: :class
    delegate :aca_shop_market_small_market_employee_count_maximum, to: :class
    delegate :aca_shop_market_transmit_scheduled_employers, to: :class
  end

  class_methods do
    def aca_shop_market_cobra_enrollment_period_in_months
      @@aca_shop_market_cobra_enrollment_period_in_months ||= Settings.aca.shop_market.cobra_enrollment_period.months
    end

    def aca_shop_market_small_market_employee_count_maximum
      @@aca_shop_market_small_market_employee_count_maximum ||= Settings.aca.shop_market.small_market_employee_count_maximum
    end

    def aca_state_abbreviation
      @aca_state_abbreviation ||= Settings.aca.state_abbreviation
    end

    def aca_state_name
      @@aca_state_name ||= Settings.aca.state_name
    end

    def aca_shop_market_employer_family_contribution_percent_minimum
      @@aca_shop_market_employer_family_contribution_percent_minimum ||= Settings.aca.shop_market.employer_family_contribution_percent_minimum
    end

    def aca_shop_market_employer_contribution_percent_minimum
      @@aca_shop_market_employer_contribution_percent_minimum ||= Settings.aca.shop_market.employer_contribution_percent_minimum
    end

    def individual_market_is_enabled?
      @@individual_market_is_enabled ||= Settings.aca.market_kinds.include? "individual"
    end

    def general_agency_enabled?
      @@genearl_agency_enabled ||= Settings.aca.general_agency_enabled
    end

    def use_simple_employer_calculation_model?
      @@use_simple_employer_calculation_model ||= (Settings.aca.use_simple_employer_calculation_model.to_s.downcase == "true")
    end

    def market_rating_areas
      @@market_rating_areas ||= Settings.aca.rating_areas
    end

    def multiple_market_rating_areas?
      @@multiple_market_rating_areas ||= Settings.aca.rating_areas.many?
    end

    def constrain_service_areas?
      @@constrain_service_areas ||= (Settings.aca.offerings_constrained_to_service_areas.to_s.downcase == "true")
    end

    def transmit_employers_immediately?
      @@transmit_employers_immediately ||= (Settings.aca.transmit_employers_immediately.to_s.downcase == "true")
    end

    def enforce_employer_attestation?
      @@enforce_employer_attestation ||= (Settings.aca.enforce_employer_attestation.to_s.downcase == "true")
    end

    def employer_attestation_is_enabled?
      @@employer_attestation ||= Settings.aca.employer_attestation
    end

    def employee_participation_ratio_minimum
      @@employee_participation_ratio_minimum ||= Settings.aca.shop_market.employee_participation_ratio_minimum.to_f
    end

    def non_owner_participation_count_minimum
      @@non_owner_participation_count_minimum ||= Settings.aca.shop_market.non_owner_participation_count_minimum.to_f
    end

    def aca_shop_market_transmit_scheduled_employers
      @@aca_shop_market_transmit_scheduled_employers ||= Settings.aca.shop_market.transmit_scheduled_employers
    end
  end
end
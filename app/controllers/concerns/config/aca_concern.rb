module Config::AcaConcern
  def aca_qle_period
    Settings.aca.qle.with_in_sixty_days
  end

  def aca_state_abbreviation
    Settings.aca.state_abbreviation
  end

  def aca_shop_market_cobra_enrollment_period_in_months
    Settings.aca.shop_market.cobra_enrollment_period.months
  end

  def individual_market_is_enabled?
    unless Settings.aca.market_kinds.include? 'individual'
     flash[:error] = "This Exchange does not support an individual marketplace"
     redirect_to root_path
    end
  end

  def general_agency_is_enabled?
     Settings.aca.general_agency_enabled
  end

  def redirect_unless_general_agency_is_enabled?
    unless Settings.aca.general_agency_enabled
      flash[:error] = "General Agencies are not supported by this Exchange"
      redirect_to broker_agencies_profile_path(@broker_agency_profile)
    end
  end
end

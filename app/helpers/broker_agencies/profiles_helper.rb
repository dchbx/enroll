module BrokerAgencies::ProfilesHelper
  def fein_display(broker_agency_profile)
    (broker_agency_profile.organization.is_fake_fein? && !current_user.has_broker_agency_staff_role?)|| (broker_agency_profile.organization.is_fake_fein? && current_user.has_hbx_staff_role?) || !broker_agency_profile.organization.is_fake_fein?
  end

  def selected_market_kind(object)
	if individual_market_is_enabled?
	object.try(:market_kind)
	else
	BrokerAgencyProfile::MARKET_KINDS_OPTIONS.values[0]
	end
  end

end
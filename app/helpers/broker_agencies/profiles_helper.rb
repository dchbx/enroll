module BrokerAgencies::ProfilesHelper
  def fein_display(broker_agency_profile)
    (broker_agency_profile.organization.is_fake_fein? && !current_user.has_broker_agency_staff_role?)|| (broker_agency_profile.organization.is_fake_fein? && current_user.has_hbx_staff_role?) || !broker_agency_profile.organization.is_fake_fein?
  end
end
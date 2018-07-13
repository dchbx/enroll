module Config::BrokerAgencyHelper
  # Allows us to conditionally display General Agency related links and information
  # This can be enabled or disabled in config/settings.yml
  # @return { True } if Settings.aca.general_agency_enabled
  # @return { False } otherwise
  def general_agency_enabled?
    Settings.aca.general_agency_enabled
  end

  def site_broker_quoting_enabled?
   Settings.site.broker_quoting_enabled
  end

end

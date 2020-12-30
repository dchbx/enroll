Rails.configuration.middleware.use Browser::Middleware do
  setting = Settings.site.block_ie_browser_after
  date = (setting.is_a? Date) ? setting : Date.strptime(setting, '%m/%d/%y')
  redirect_to unsupported_browser_path if browser.ie? && Settings.site.block_ie_browser && date <= TimeKeeper.date_of_record
end
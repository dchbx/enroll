Config.setup do |config|
  config.const_name = "Settings"
end

SponsoredBenefits.configure do |config|
  config.settings = Settings
end

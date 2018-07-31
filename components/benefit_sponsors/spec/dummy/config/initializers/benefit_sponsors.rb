Config.setup do |config|
  config.const_name = "Settings"
end

BenefitSponsors.configure do |config|
  config.settings = Settings
end

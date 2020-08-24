# frozen_string_literal: true

Config.setup do |config|
  config.const_name = "Settings"
end

FinancialAssistance.configure do |config|
  config.settings = Settings
end

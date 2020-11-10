# frozen_string_literal: true

Given(/^the Reinstate feature configuration is enabled$/) do
  enable_feature :benefit_application_reinstate
end

Given(/^the Reinstate feature configuration is disabled$/) do
  disable_feature :benefit_application_reinstate
end

Then(/^the user will (.*) Reinstate button$/) do |action|
  if action == 'see'
    page.has_css?('Reinstate') == true
  else
    page.has_css?('Reinstate') == false
  end
end

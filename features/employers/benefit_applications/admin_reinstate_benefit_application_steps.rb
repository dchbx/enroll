# frozen_string_literal: true

Given(/^the Reinstate feature configuration is enabled$/) do
  enable_feature :benefit_application_reinstate
end

Given(/^the Reinstate feature configuration is disabled$/) do
  disable_feature :benefit_application_reinstate
end

Then(/^the user will (.*) Reinstate button$/) do |action|
  action == 'see' ? (page.has_css?('Reinstate') == true) : (page.has_css?('Reinstate') == false)
end

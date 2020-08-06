# frozen_string_literal: true

Then (/^Hbx Admin sees Families link$/) do
  expect(page).to have_text("Families")
end

When(/^Hbx Admin click Families link$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-families').click
  wait_for_ajax
  find(:xpath, "//*[@id='myTab']/li[2]/ul/li[2]/a", :wait => 10).click
  wait_for_ajax
end

When(/^Hbx Admin click Families dropdown/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-families').click
  wait_for_ajax
end

Then(%r{^Hbx Admin should see an Edit APTC / CSR link$}) do
  find_link('Edit APTC / CSR').visible?
end

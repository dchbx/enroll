# frozen_string_literal: true

Then(/^Hbx Admin sees Families link$/) do
  expect(page).to have_text("Families")
end

When(/^Hbx Admin click Families link$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-families').click
  wait_for_ajax
  find(:xpath, "//*[@id='myTab']/li[2]/ul/li[2]/a", :wait => 10).click
  wait_for_ajax
end

When(/^Hbx Admin clicks Actions button$/) do
  find_all('.dropdown.pull-right', text: 'Actions')[0].click
end

When(/^Hbx Admin click Families dropdown/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-families').click
  wait_for_ajax
end

Then(/^Hbx Admin should see an Edit APTC \/ CSR link$/) do
  find_link('Edit APTC / CSR').visible?
end

Given(/^User with tax household exists$/) do
  create_thh_for_family
end


When(/^Hbx Admin clicks on the Update APTC CSR button$/) do
  find_link('Edit APTC / CSR').click
end


Then(/^Hbx Admin should see cat plan error message$/) do
  wait_for_ajax
  fill_in "aptc_applied_#{@enrollment.id}", with: "23.00"
  find(".toggle_update_btn").click
  wait_for_ajax(3,2)
  expect(page).to have_content(Settings.aptc_errors.cat_plan_error)
end

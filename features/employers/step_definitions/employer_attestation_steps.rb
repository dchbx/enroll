# frozen_string_literal: true

Then (/^Employer Staff should see dialog with Attestation warning$/) do
  wait_for_ajax(3,2)
  expect(page).to have_content('Publish Anyways')
  expect(page).to have_content('Cancel')
end

Then (/^Employer Staff should not see force publish$/) do
  wait_for_ajax(3,2)
  expect(page).not_to have_content('Force Publish')
  expect(page).to have_content('Cancel')
end

Then (/^Employer Staff clicks cancel button in Attestation warning dialog$/) do
  find('.interaction-click-control-cancel').click
end

Then (/^Employer Staff clicks go back button in Attestation warning dialog$/) do
  find('#publishPlanYear .interaction-click-control-go-back').click
end

Then (/^Employer Staff should redirect to plan year edit page$/) do
  wait_for_ajax
  expect(page).to have_content('Edit Plan Year')
end

Then(/^Plan Year should be moved to (.*)$/) do |state|
  wait_for_ajax
  expect(page).to have_content(state)
end

When (/I click Iam Admin button/) do
  find(".interaction-click-control-i'm-an-admin").click
end

When (/^I visit sign up page$/) do
  visit('/users/sign_up')
end

When (/^I click HBX portal$/) do
  visit('/exchanges/hbx_profiles')
  #find('.interaction-click-control-hbx-portal').click
end

When(/^Admin click all employers link/) do
  find('.interaction-click-control-employers').click
end

When (/^Admin clicks employer attestation filter$/) do
  find_by_id('Tab:employer_attestations', wait: 10).click
end

And(/^Admin clicks (.*) filter in employer attestation$/) do |state|
  wait_for_ajax
  find_by_id("Tab:employer_attestations-#{state}").click
end

Then (/^Admin should see Employer with (.*) status$/) do |state|
  wait_for_ajax
  expect(find(:xpath, '//*[@id="effective_datatable_wrapper"]/div/div/div[3]/div/table/tbody/tr[1]/td[10]')).to have_content state
end

When (/^Admin clicks attestation action$/) do
  find(:xpath, '//*[@id="effective_datatable_wrapper"]/div/div/div[3]/div/table/tbody/tr[1]/td[11]/div').click
  wait_for_ajax
  find(:xpath, '//*[@id="effective_datatable_wrapper"]/div/div/div[3]/div/table/tbody/tr[1]/td[11]/div/ul/li[3]/a').click
end

Then (/^Admin should see attestation document$/) do
  expect(find(:xpath, '//*[@id="attestation_documents_table"]/div/table/tbody/tr[1]/td[1]')).to have_content "Submitted"
  expect(find(:xpath, '//*[@id="attestation_documents_table"]/div/table/tbody/tr[1]/td[2]')).to have_content "JavaScript.pdf"
end

When (/^Admin clicks view attestation document$/) do
  find(:xpath, '//*[@id="attestation_documents_table"]/div/table/tbody/tr[1]/td[6]/a').click
end

Then (/^Admin should see preview and attestation form$/) do
  wait_for_ajax
  expect(find(:xpath, '//*[@id="attestation_documents_table"]')).to have_content "Approve"
  expect(find(:xpath, '//*[@id="attestation_documents_table"]')).to have_content "Reject"
  expect(find(:xpath, '//*[@id="attestation_documents_table"]')).to have_content "Request Additional Information"
end

When (/^Admin clicks submit in employer attestation form$/) do
  accept_alert do
    first('#attestation_documents_table .btn-primary',:text => /SUBMIT/i).click
  end
end

Then (/^Admin should see attestation updated message$/) do
  expect(find('.alert-notice')).to have_content("Employer attestation updated successfully")
end

When (/^Admin clicks employer in employers_attestation filter$/) do
  find(:xpath, '//*[@id="effective_datatable_wrapper"]/div/div/div[3]/div/table/tbody/tr[1]/td[1]').click
end

Then (/^Employer Staff should see attestation status (.*)$/) do |state|
  wait_for_ajax

  expect(page).to have_content state
end

And(/^Employer should still see attestation upload button enabled$/) do
  expect(find('.interaction-click-control-upload')[:class].split.include?('disabled')).to be_falsey
end

And(/^Employer should see attestation upload button disabled$/) do
  expect(find('.interaction-click-control-upload')[:class].split.include?('disabled')).to be_truthy
end

When(/^Admin choose (.*)$/) do |state|
  find('div.radio', text: state).click
end

When(/^Admin enters the information needed$/) do
  select "Unable To Open Document", :from => "reason_for_rejection"
end

When(/^Employer staff clicks employees tab$/) do
  find('.interaction-click-control-employees').click
end

Then (/^Employer staff should employees coverage status as canceled$/) do
  expect(page).to have_content "Canceled"
end

When (/^Employer Staff clicks documents tab$/) do
  wait_for_ajax
  find('.interaction-click-control-documents').click
end

def enter_plan_year_info
  wait_for_ajax(2,2)
  find('span', text: 'SELECT START ON').click
  find(:xpath, "//li[@data-index='1'][contains(., '#{effective_period.min.year}')]", :wait => 3).click
  find('.interaction-field-control-fteemployee').click
  fill_in 'benefit_application[fte_count]', with: '3'
  fill_in 'benefit_application[pte_count]', with: '3'
  fill_in 'benefit_application[msp_count]', with: '3'
  find('.interaction-click-control-continue').click
  sleep(3)
  #Benefit Package
  wait_for_ajax
  fill_in 'benefit_package[title]', with: 'Silver PPO Group'
  fill_in 'benefit_package[description]', with: 'Testing'
end

And(/^.+ should be able to enter sole source plan year, benefits, relationship benefits for employer$/) do
  enter_plan_year_info

  find(:xpath, '//li/label[@for="plan_year_benefit_groups_attributes_0_plan_option_kind_sole_source"]').click
  wait_for_ajax
  find('.sole-source-plan-tab a').click
  wait_for_ajax
  find('.reference-plans label').click
  wait_for_ajax
  fill_in "plan_year[benefit_groups_attributes][0][composite_tier_contributions_attributes][0][employer_contribution_percent]", :with => 50
  fill_in "plan_year[benefit_groups_attributes][0][composite_tier_contributions_attributes][3][employer_contribution_percent]", :with => 50
  wait_for_ajax
  find('.interaction-click-control-create-plan-year').click
end

When(/^.+ try to create plan year with less than 33% contribution for spouse, domestic partner and child under 26$/) do
  enter_plan_year_info
  find(:xpath, '//*[@id="metal-level-select"]/div/ul/li[1]/a').click
  wait_for_ajax
  find(:xpath, '//*[@id="carrier"]/div[1]/div/label').click
  sleep 2
  wait_for_ajax
  expect(page).to have_content('Select Your Reference Plan')
  wait_for_ajax
  page.first('.reference-plans label').click
  fill_in "benefit_package[sponsored_benefits_attributes][0][sponsor_contribution_attributes][contribution_levels_attributes][1][contribution_factor]", :with => 50
  fill_in "benefit_package[sponsored_benefits_attributes][0][sponsor_contribution_attributes][contribution_levels_attributes][2][contribution_factor]", :with => 30
  fill_in "benefit_package[sponsored_benefits_attributes][0][sponsor_contribution_attributes][contribution_levels_attributes][3][contribution_factor]", :with => 31
  fill_in "benefit_package[sponsored_benefits_attributes][0][sponsor_contribution_attributes][contribution_levels_attributes][4][contribution_factor]", :with => 32
  wait_for_ajax
end

Then (/^.+ can not create plan year$/) do
  find('.interaction-click-control-create-plan-year').has_css?('.disabled')
end

And(/^.+ should be able to enter plan year, benefits, relationship benefits for employer$/) do
  enter_plan_year_info
  find(:xpath, '//*[@id="metal-level-select"]/div/ul/li[1]/a').click
  wait_for_ajax
  find(:xpath, '//*[@id="carrier"]/div[1]/div/label').click
  sleep 2
  expect(page).to have_content('Select Your Reference Plan')
  wait_for_ajax
  page.first('.reference-plans label').click
  fill_in "benefit_package[sponsored_benefits_attributes][0][sponsor_contribution_attributes][contribution_levels_attributes][1][contribution_factor]", :with => 50
  fill_in "benefit_package[sponsored_benefits_attributes][0][sponsor_contribution_attributes][contribution_levels_attributes][2][contribution_factor]", :with => 50
  fill_in "benefit_package[sponsored_benefits_attributes][0][sponsor_contribution_attributes][contribution_levels_attributes][3][contribution_factor]", :with => 100
  fill_in "benefit_package[sponsored_benefits_attributes][0][sponsor_contribution_attributes][contribution_levels_attributes][4][contribution_factor]", :with => 100
  sleep 2
  find(:xpath, '//*[@id="referencePlanShell"]/div/div[1]/h1').click
  find('.interaction-click-control-create-plan-year').click
end

Then(/^Employer clicks delete in actions$/) do
  accept_alert do
    find(:xpath, '//*[@id="effective_datatable_wrapper"]/div/div/div[3]/div/table/tbody/tr[1]/td[6]').click
    find(:xpath, '//*[@id="effective_datatable_wrapper"]/div/div/div[3]/div/table/tbody/tr[1]/td[6]/div/ul/li[2]/a').click
  end
end

Then(/^Employer should see disabled delete button in actions$/) do
  find(:xpath, '//*[@id="effective_datatable_wrapper"]/div/div/div[3]/div/table/tbody/tr[1]/td[6]').click
  find(:xpath, '//*[@id="effective_datatable_wrapper"]/div/div/div[3]/div/table/tbody/tr[1]/td[6]/div/ul/li[2]/a')['disabled'] == "disabled"
end

Then(/^Employer should not see submitted document$/) do
  find('.interaction-click-control-documents').click
  expect(page).to have_content('No data available in table')
end

Then(/^Employer should see Accepted document$/) do
  wait_for_ajax
  expect(page).to have_content('Accepted')
end

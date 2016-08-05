Capybara.ignore_hidden_elements = false

module BrokerWorld
  def broker(*traits)
    attributes = traits.extract_options!
    @broker ||= FactoryGirl.create :user, *traits, attributes
  end

  def broker_agency(*traits)
    attributes = traits.extract_options!
    @broker_agency ||= FactoryGirl.create :broker , *traits, attributes
  end

end

World(BrokerWorld)

Given (/^that a broker exists$/) do
  broker_agency
  broker :with_family, :broker_with_person, organization: broker_agency
end

And(/^the broker is signed in$/) do
  login_as broker, scope: :user
end

When(/^he visits the Roster Quoting tool$/) do
  visit my_quotes_broker_agencies_quotes_path
end

When(/^click on the New Quote button$/) do
  click_link 'New Quote'
end

When(/^click on the Upload Employee Roster button$/) do
  click_link "Upload Employee Roster"
end

When(/^the broker clicks on the Select File to Upload button$/) do
  find(:xpath,"//*[@id='modal-wrapper']/div/form/label").trigger('click')
  within '.upload_csv' do
    attach_file('employee_roster_file', "#{Rails.root}/spec/test_data/employee_roster_import/Employee_Roster_sample.xlsx")
  end
end

Then(/^the broker clicks upload button$/) do
  click_button 'Upload'
end

Then(/^the broker should see the data in the table$/) do
  expect(page).to have_selector("input#quote_quote_households_attributes_0_family_id[value=\"1\"]")
  expect(page).to have_selector("input#quote_quote_households_attributes_1_family_id[value=\"2\"]")
  expect(page).to have_selector('div.panel.panel-default div input.uidatepicker', count: 10)
  expect(page).to have_selector("#quote_quote_households_attributes_0_quote_members_attributes_0_dob[value=\"06/01/1980\"]")
  expect(page).to have_selector("input#quote_quote_households_attributes_2_quote_members_attributes_0_first_name[value=\"John\"]")
  expect(page).to have_selector("input#quote_quote_households_attributes_1_quote_members_attributes_0_last_name[value=\"Ba\"]")
end

Then(/^the broker enters the quote effective date$/) do
  select "#{Date.today.next_month.strftime("%B %Y")}", :from => "quote_start_on"
end

When(/^broker enters valid information$/) do
  fill_in 'quote[quote_name]', with: 'Test Quote'
  fill_in 'quote[quote_households_attributes][0][quote_members_attributes][0][dob]', with: "11/11/1991"
  select "Employee", :from => "quote_quote_households_attributes_0_quote_members_attributes_0_employee_relationship"
  fill_in 'quote[quote_households_attributes][0][quote_members_attributes][0][first_name]', with: "John"
  fill_in 'quote[quote_households_attributes][0][quote_members_attributes][0][last_name]', with: "Bandari"
end

When(/^the broker clicks on the Save Changes button$/) do
  find('.interaction-click-control-save-changes').trigger 'click'
end

Then(/^the broker should see a successful message$/) do
  expect(page).to have_content('Successfully saved quote/employee roster.')
end

Then(/^the broker clicks on Back to Quotes button$/) do
  find('.interaction-click-control-back-to-quotes').trigger 'click'
end

Then(/^the broker clicks Actions dropdown$/) do
  find('#dropdownMenu1').trigger 'click'
end

When(/^the broker clicks delete$/) do
  find('a', text: "Delete"). trigger 'click'
end

Then(/^the broker sees the confirmation$/) do
  expect(page).to have_content('Are you sure you want to delete Test Quote?')
end

Then(/^the broker clicks Delete Quote$/) do
  click_link 'Delete Quote'
end

Then(/^the quote should be deleted$/) do
  expect(page).to have_content('Successfully deleted Test Quote.')
end

Then(/^adds a new benefit group$/) do
  fill_in "quote[quote_benefit_groups_attributes][1][title]", with: 'My Benefit Group'
  find('.interaction-click-control-save-changes').trigger 'click'
end

Then(/^the broker assigns the benefit group to the family$/) do
  select "My Benefit Group", :from => "quote[quote_households_attributes][0][quote_benefit_group_id]"
end

Then(/^the broker saves the quote$/) do
  find('.interaction-click-control-save-changes').trigger 'click'
end

When(/^the broker clicks on quote$/) do
  click_link 'Test Quote'
end

Given(/^the Plans exist$/) do
  open_enrollment_start_on = TimeKeeper.date_of_record.end_of_month + 1.day
  open_enrollment_end_on = open_enrollment_start_on + 12.days
  start_on = open_enrollment_start_on + 1.months
  end_on = start_on + 1.year - 1.day
  plan1 = FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: start_on.year, csr_variant_id: "01")
  plan2 = FactoryGirl.create(:plan, :with_premium_tables, market: 'shop', metal_level: 'bronze', active_year: start_on.year, csr_variant_id: "01")
  Caches::PlanDetails.load_record_cache!
  $quote_shop_health_plans = [plan1,plan2]
end

Then(/^the broker enters Employer Contribution percentages$/) do
  page.execute_script(" QuoteSliders.slider_listeners()")
  page.execute_script("$('#pct_employee').bootstrapSlider({})")
  sleep(2)
  find(:xpath, "//div[contains(@class, 'health')]//*[@id='employee_slide_input']").set("80")
  page.execute_script("$('#pct_employee').bootstrapSlider('setValue', employee_value= 80)")
  sleep(2)
  page.execute_script("$('#pct_employee').trigger('slideStop')")
end

Then(/^the broker filters the plans$/) do
  find(:xpath, "//*[@id='quote-plan-list']/label[1]").trigger("click")
  find(:xpath, "//*[@id='quote-plan-list']/label[2]").trigger("click")
end

Then(/^the broker clicks Compare Costs$/) do
  find('#CostComparison').trigger 'click'
end

When(/^the broker selects the Reference Plan$/) do
  Capybara.default_max_wait_time = 3
  find('div#single_plan_1').trigger("click")
end

Then(/^the broker clicks Publish Quote button$/) do
  click_button 'Publish Quote'
end

Then(/^the broker sees that the Quote is published$/) do
  expect(page).to have_content('Your quote has been published')
end

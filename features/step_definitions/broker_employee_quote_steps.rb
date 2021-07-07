#Capybara.ignore_hidden_elements = false

module BrokerWorld
  def broker(*traits)
    attributes = traits.extract_options!
    @broker ||= FactoryBot.create(:user, :broker_with_person, *traits, attributes)
  end

  def broker_agency(*traits)
    attributes = traits.extract_options!
    @broker_agency ||= FactoryBot.create :broker, *traits, attributes
  end
end

World(BrokerWorld)

Given (/^that a broker exists$/) do
  broker_agency
  broker :with_family, :broker_with_person, organization: broker_agency
  broker_agency_profile = broker_agency.broker_agency_profile
  broker_agency_account = FactoryBot.create(:broker_agency_account, broker_agency_profile: broker_agency_profile, writing_agent_id: broker_agency_profile.primary_broker_role.id)
  employer_profile = FactoryBot.create(:employer_profile)
  employer_profile.broker_agency_accounts << broker_agency_account
  employer_profile.save!
end

And(/^the broker is signed in$/) do
  login_as broker
end

When(/^he visits the Roster Quoting tool$/) do
  visit my_quotes_broker_agencies_broker_role_quotes_path(broker.person.broker_role.id)
end

When(/^click on the New Quote button$/) do
  click_link 'New Quote'
end

When(/^.+ clicks on the Add Prospect Employer button$/) do
  find(:xpath, "//*[@id='myTabContent']/div/div[4]/div/a").click
end

And(/^Primary Broker creates new Prospect Employer with default_office_location$/) do
  find('#organization_legal_name').click
  fill_in 'organization[legal_name]', :with => "emp1"
  fill_in 'organization[dba]', :with => 101010

  find('.interaction-choice-control-organization-entity-kind').click
  find(".interaction-choice-control-organization-entity-kind-2").click

  find(:xpath, "//select[@name='organization[entity_kind]']/option[@value='c_corporation']")
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_1]', :with => "1818"
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_2]', :with => "exp st"
  fill_in 'organization[office_locations_attributes][0][address_attributes][city]', :with => "Washington"
  fill_in 'organization[office_locations_attributes][0][address_attributes][zip]', :with => "20002"
  fill_in 'organization[office_locations_attributes][0][phone_attributes][area_code]', :with => "202"
  fill_in 'organization[office_locations_attributes][0][phone_attributes][number]', :with => "5551212"
  fill_in 'organization[office_locations_attributes][0][phone_attributes][extension]', :with => "22332"
  find('.interaction-click-control-confirm').click
end

And(/^.+ should see successful message$/) do
  expect(page).to have_content("Prospect Employer (#{SponsoredBenefits::Organizations::PlanDesignOrganization.all.first.legal_name}) Added Successfully.")
end

And(/^the broker clicks Actions dropdown and clicks View Quotes from dropdown menu$/) do
  path = SponsoredBenefits::Organizations::PlanDesignOrganization.all.first.id.to_s
  find("#dropdown_for_plan_design_" + path, :text => "Actions").click
  find("#plan_design_#{path}> ul > li:nth-child(1) > a", :text => "View Quotes").click
  wait_for_ajax(3, 2)
end

Then(/^Primary Broker should be on the Roster page of a View quote$/) do
  expect(page).to have_content("Manage Quotes for #{SponsoredBenefits::Organizations::PlanDesignOrganization.all.first.legal_name}")
end

And(/^the broker clicks Actions dropdown and clicks Create Quote from dropdown menu$/) do
  #plan = FactoryBot.create(:plan, :with_premium_tables, active_year: TimeKeeper.date_of_record.year)
  path = SponsoredBenefits::Organizations::PlanDesignOrganization.all.first.id.to_s
  find("#dropdown_for_plan_design_" + path, :text => "Actions").click
  find("#plan_design_#{path}> ul > li:nth-child(2) > a", :text => "Create Quote").click
  wait_for_ajax(3, 2)
end

Then(/^Primary Broker should be on the Roster page of a Create quote$/) do
  expect(page).to have_content("Quote for #{SponsoredBenefits::Organizations::PlanDesignOrganization.all.first.legal_name}")
end

And(/^Primary Broker enters quote name$/) do
  find('#forms_plan_design_proposal_title').click
  fill_in 'forms_plan_design_proposal[title]', :with => "Test Quote"

  find(:xpath, "//*[@id='new_forms_plan_design_proposal']/div[1]/div/div[1]/div[2]/div/div[2]/div").click
  expect(page).to have_content((TimeKeeper.date_of_record + 2.months).strftime("%B %Y"))
  find('li', :text => "#{(TimeKeeper.date_of_record + 2.months).strftime('%B %Y')}").click
  wait_for_ajax(3, 2)
end

Then(/^.+ sees that publish button is (.*)$/) do |publish_btn|
  wait_for_ajax(3, 2)
  find(:xpath, "//*[@id='new_forms_plan_design_proposal']/div[9]", :visible => false).click
  wait_for_ajax(3, 2)
  if publish_btn == 'disabled'
    expect(page).to have_selector(:button, "Save Quote", disabled: true)
  else
    expect(find("#submitPlanDesignProposal")[:class].include?('disabled')).to eql false
  end
end

And(/^.+ sees quote for (.*) employer$/) do |employer_name|
  expect(page).to have_content("Quote for #{employer_name}")
end

And(/^the broker clicks on Select Health Benefits button$/) do
  find('.interaction-click-control-select-health-benefits').click
end

When(/^.+ clicks Actions for that Employer$/) do
  find('.dropdown.pull-right', text: 'Actions').click
  sleep 5
end

Then(/^.+ sees Create Quote button$/) do
  expect(page).to have_css('.btn.btn-xs', text: 'Create Quote')
end

Then(/^.+ clicks on Create Quote button$/) do
  find('.btn.btn-xs', text: 'Create Quote').click
end



Then(/^broker publishes the quote$/) do
  wait_for_ajax(3, 2)
  find(:xpath, "//*[@id='new_forms_plan_design_proposal']/div[9]", :visible => false).click
  find(:xpath,"//*[@id='new_forms_plan_design_proposal']/div[3]/div/div/div[2]/div[1]/div/div[1]/label/div/div[2]/div/div[1]/h3").click
  wait_for_ajax(3, 2)
  find('.interaction-click-control-publish-quote').click
end

Then(/^the broker selects plan offerings by metal level and enters (.*) for employee and deps$/) do |int|
  wait_for_ajax(3, 2)
  find(:xpath, "//*[@id='pdp-bms']/div/ul/li[2]/label/div").click
  wait_for_ajax(3, 2)
  expect(page).to have_content("Gold")
  find(:xpath, "//*[@id='metalLevelCarrierList']/div[3]/div[2]/label/h3").click
  wait_for_ajax(3, 2)
  fill_in "forms_plan_design_proposal[profile][benefit_sponsorship][benefit_application][benefit_group][relationship_benefits_attributes][0][premium_pct]", with: int.to_i
  fill_in "forms_plan_design_proposal[profile][benefit_sponsorship][benefit_application][benefit_group][relationship_benefits_attributes][1][premium_pct]", with: int.to_i
  fill_in "forms_plan_design_proposal[profile][benefit_sponsorship][benefit_application][benefit_group][relationship_benefits_attributes][2][premium_pct]", with: int.to_i
  fill_in "forms_plan_design_proposal[profile][benefit_sponsorship][benefit_application][benefit_group][relationship_benefits_attributes][3][premium_pct]", with: int.to_i
end

Then(/^the broker should see that the save benefits button is enabled$/) do
  expect(find("#submitPlanDesignProposal")[:class].include?('disabled')).to eql false
end

And(/^.+ should see successful message of published quote$/) do
  expect(page).to have_content("Quote Published")
end

And(/^Primary Broker should see the quote roster is empty$/) do
  expect(page).not_to have_button('Actions')
end

When(/^click on the Upload Employee Roster button$/) do
  click_link "Upload Roster"
end

When(/^the broker clicks on the Select File to Upload button$/) do
  Capybara.ignore_hidden_elements = false
  find(:xpath,"//*[@id='modal-wrapper']/div/form/label").click
  within '.upload_csv' do
    attach_file('employee_roster_file', "#{Rails.root}/spec/test_data/employee_roster_import/Employee_Roster_sample.xlsx")
  end
  Capybara.ignore_hidden_elements = true
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
  select "#{(TimeKeeper.date_of_record+3.month).strftime("%B %Y")}", :from => "quote_start_on"
end

When(/^the broker selects employer type$/) do
 #find('.interaction-choice-control-quote-employer-type').click()
 select "Prospect", :from => "quote_employer_type"
 fill_in 'quote[employer_name]', with: "prospect test Employee"
end

When(/^broker enters valid information$/) do
  fill_in 'quote[quote_name]', with: 'Test Quote'
  fill_in 'quote[quote_households_attributes][0][quote_members_attributes][0][dob]', with: "11/11/1991"
  select "Employee", :from => "quote_quote_households_attributes_0_quote_members_attributes_0_employee_relationship"
  fill_in 'quote[quote_households_attributes][0][quote_members_attributes][0][first_name]', with: "John"
  fill_in 'quote[quote_households_attributes][0][quote_members_attributes][0][last_name]', with: "Bandari"
end

When(/^the broker clicks on the Save Changes button$/) do
  find('.interaction-click-control-save-changes').click
end

Then(/^the broker should see a successful message$/) do
  expect(page).to have_content('Successfully saved quote/employee roster.')
end

Then(/^the broker clicks on Home button$/) do
  sleep 2
  find('.interaction-click-control-home').click
end

Then(/^the broker clicks Actions dropdown$/) do
  find('.dropdown-toggle', :text => "Actions").click
end

When(/^the broker clicks delete$/) do
  find('a', text: "Delete"). click
end

Then(/^the broker sees the confirmation$/) do
  expect(page).to have_content('Are you sure you want to delete Test Quote?')
end

Then(/^the broker clicks Delete Quote$/) do
  expect(page).to have_content(/Test Quote/)
  click_link 'Delete Quote'
end

Then(/^the quote should be deleted$/) do
  sleep 1
  expect(page).not_to have_content(/Test Quote/)
  expect(page).to have_content(/No data available in table/)
end

Then(/^adds a new benefit group$/) do
  fill_in "quote[quote_benefit_groups_attributes][0][title]", with: 'My Benefit Group'
  find('.interaction-click-control-save-changes').click
end

Then(/^the broker saves the quote$/) do
  find('.interaction-click-control-save-changes').click
end

When(/^the broker clicks on quote$/) do
  sleep 1
  click_link 'Test Quote'
end

Given(/^the Plans exist$/) do
  sys_year = TimeKeeper.date_of_record.year

  # TODO: create bcps with proper OE dates and check the TimeKeeper against it.
  previous_year = if (Date.new(sys_year, 11, 1)..Date.new(sys_year, 12, 31)).cover? TimeKeeper.date_of_record
                    TimeKeeper.date_of_record.year
                  else
                    TimeKeeper.date_of_record.year - 1
                  end

  [previous_year, (previous_year + 1)].each do |year|
    FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', metal_level: 'gold', active_year: year, deductible: 2000, csr_variant_id: "01", coverage_kind: 'health')
    FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', metal_level: 'silver', active_year: year, deductible: 5000, csr_variant_id: "01", coverage_kind: 'health')
    FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', metal_level: 'bronze', active_year: year, deductible: 3000, csr_variant_id: "01", coverage_kind: 'health')
    FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', dental_level: 'high', active_year: year, deductible: 4000, coverage_kind: 'dental')
    FactoryBot.create(:plan, :with_rating_factors, :with_premium_tables, market: 'shop', dental_level: 'low', active_year: year, deductible: 4000, coverage_kind: 'dental')
  end
  Caches::PlanDetails.load_record_cache!
end

Then(/^the broker enters Employer Contribution percentages for health plan$/) do
  page.execute_script(" QuoteSliders.slider_listeners()")
  page.execute_script("$('#pct_employee').bootstrapSlider({})")
  sleep(1)
  find(:xpath, "//div[contains(@class, 'health')]//*[@id='employee_slide_input']").set("80")
  page.execute_script("$('#pct_employee').bootstrapSlider('setValue', employee_value= 80)")
  sleep(1)
  page.execute_script("$('#pct_employee').trigger('slideStop')")
end

Then(/^the broker enters Employer Contribution percentages for dental plan$/) do
  page.execute_script(" QuoteSliders.slider_listeners()")
  page.execute_script("$('#dental_pct_employee').bootstrapSlider({})")
  sleep(1)
  find(:xpath, "//div[contains(@class, 'dental')]//*[@id='employee_slide_input']").set("80")
  page.execute_script("$('#dental_pct_employee').bootstrapSlider('setValue', employee_value= 80)")
  sleep(1)
  page.execute_script("$('#dental_pct_employee').trigger('slideStop')")
end

Then(/^the broker filters health plans$/) do
  find(:xpath, "//*[@id='quote-plan-list']/label[1]").click
  find(:xpath, "//*[@id='quote-plan-list']/label[2]").click
end

Then(/^the broker filters dental plans$/) do
  find(:xpath, "//*[@id='quote-dental-plan-list']/label[1]").click
  find(:xpath, "//*[@id='quote-dental-plan-list']/label[2]").click
end

Then(/^the broker clicks Compare Costs for health plans$/) do
  find('#CostComparison').click
end

Then(/^the broker clicks Compare Costs for dental plans$/) do
  find('#DentalCostComparison').click
end

When(/^the broker selects the Reference Health Plan$/) do
  wait_for_ajax(3)
  find('div#single_plan_1').click
end

When(/^the broker selects the Reference Dental Plan$/) do
  wait_for_ajax(3)
  find('div#single_dental_plan_1').click
  wait_for_ajax
end

Then(/^the broker clicks Publish Quote button$/) do
  find('#publish_quote').click
end

Then(/^the broker sees that the Quote is published$/) do
  expect(page).to have_content('Your quote has been published')
end

When(/^the broker clicks Dental Features$/) do
  find('.interaction-click-control-dental-features-and-cost-criteria').click
end

And(/^prospect employer exist$/) do
  find(BrokerHomePage.employers_tab).click
  find(BrokerEmployersPage.add_prospect_employer_btn).click
  fill_in BrokerAddProspectEmployerPage.legal_name, with: 'emp1'
  fill_in BrokerAddProspectEmployerPage.dba, with: '101010'
  find(BrokerAddProspectEmployerPage.entity_kind_dropdown).click
  find(BrokerAddProspectEmployerPage.select_c_corporation).click
  fill_in BrokerAddProspectEmployerPage.address_1, with: '1818 exp st'
  fill_in BrokerAddProspectEmployerPage.city, with: 'Washington'
  fill_in BrokerAddProspectEmployerPage.zip, with: '20002'
  fill_in BrokerAddProspectEmployerPage.area_code, with: '202'
  fill_in BrokerAddProspectEmployerPage.number, with: '5551212'
  find(BrokerAddProspectEmployerPage.confirm_btn).click
end

And(/^Primary broker clicks Actions dropdown and clicks Create Quote$/) do
 find(BrokerEmployersPage.actions_dropdown).click
 expect(page).to have_css('.btn.btn-xs', text: 'Create Quote')
 find(BrokerEmployersPage.create_quote).click
end

And(/^Primary broker clicks on Select Health Benefits button$/) do
  find(BrokerCreateQuotePage.select_health_benefits_btn).click
end

And(/^Primary broker selects plan offerings by metal level and enters (.*) for employee and deps$/) do |int|
  wait_for_ajax(2, 2)
  find(BrokerHealthBenefitsPage.by_meta_level_tab).click
  wait_for_ajax(2, 2)
  expect(page).to have_content("Gold")
  choose(BrokerHealthBenefitsPage.gold_radiobtn)
  wait_for_ajax(2, 2)
  fill_in BrokerHealthBenefitsPage.employer_employee_contribution, with: int.to_i
  fill_in BrokerHealthBenefitsPage.employer_spouse_contribution, with: int.to_i
  fill_in BrokerHealthBenefitsPage.employer_domestic_partner_contribution, with: int.to_i
  fill_in BrokerHealthBenefitsPage.employer_child_under_26_contribution, with: int.to_i
end

And (/^Primary broker publishes the quote$/) do
  wait_for_ajax(3, 2)
  find(BrokerHealthBenefitsPage.select_refrence_plan).click
  wait_for_ajax(3, 2)
  find(BrokerHealthBenefitsPage.publish_quote_btn).click
  expect(page).to have_content("Quote Published")
end

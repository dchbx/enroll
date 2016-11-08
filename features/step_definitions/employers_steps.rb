Then(/^.+ should see a welcome page with successful sign in message$/) do
  Watir::Wait.until(30) { @browser.text.include?(/Signed in successfully./) }
  screenshot("employer_portal_sign_in_welcome")
  expect(@browser.text.include?("Signed in successfully.")).to be_truthy
  @browser.a(text: /Continue/).wait_until_present
  expect(@browser.a(text: /Continue/).visible?).to be_truthy
  @browser.a(text: /Continue/).click
end

Then(/^.+ should see fields to search for person and employer$/) do
  Watir::Wait.until(30) { @browser.text.include?(/Personal Information/) }
  screenshot("employer_portal_person_search")
  expect(@browser.text.include?(/Personal Information/)).to be_truthy
end

Then(/^.+ should see an initial fieldset to enter my name, ssn and dob$/) do
  @browser.text_field(name: "person[first_name]").wait_until_present
  @browser.text_field(name: "person[first_name]").set("John")
  @browser.text_field(name: "person[last_name]").set("Doe")
  @browser.text_field(name: "person[date_of_birth]").set("10/10/1985")
  @browser.text_field(name: "person[first_name]").click
  @browser.text_field(name: "person[ssn]").set("111000999")
  @browser.button(value: /Search Person/).wait_until_present
  screenshot("employer_portal_person_search_criteria")
  @browser.button(value: /Search Person/).fire_event("onclick")
end

And(/^My user data from existing the fieldset values are prefilled using data from my existing account$/) do
  @browser.button(value: /This is my info/).wait_until_present
  screenshot("employer_portal_person_match_form")
  @browser.button(value: /This is my info/).fire_event("onclick")
  @browser.text_field(name: "person[addresses_attributes][0][address_1]").wait_until_present
  @browser.text_field(name: "person[addresses_attributes][0][address_1]").set("12000 Address 1")
  @browser.text_field(name: "person[addresses_attributes][0][address_2]").set("Suite 100")
  @browser.text_field(name: "person[addresses_attributes][0][city]").set("city")
  @browser.text_field(name: "person[addresses_attributes][0][state]").set("st")
  @browser.text_field(name: "person[addresses_attributes][0][zip]").set("20001")
  @browser.text_field(name: "person[phones_attributes][0][full_phone_number]").set("9999999999")
  @browser.text_field(name: "person[phones_attributes][1][full_phone_number]").set("8888888888")
  @browser.text_field(name: "person[emails_attributes][0][address]").set("home@example.com")
  @browser.text_field(name: "person[emails_attributes][1][address]").set("work@example.com")
  @browser.text_field(name: "person[emails_attributes][1][address]").click
  screenshot("employer_portal_person_data")
  @browser.button(id: /continue-employer/).wait_until_present
  expect(@browser.button(id: /continue-employer/).visible?).to be_truthy
  @browser.button(id: /continue-employer/).click
end

And(/^.+ should see a form with a fieldset for Employer information, including: legal name, DBA, fein, entity_kind, broker agency, URL, address, and phone$/) do
  @browser.button(value: /Search Employers/).wait_until_present
  screenshot("employer_portal_employer_search_form")
  @employer_profile = FactoryGirl.create(:employer_profile)

  @browser.text_field(name: "employer_profile[legal_name]").set(@employer_profile.legal_name)
  @browser.text_field(name: "employer_profile[dba]").set(@employer_profile.dba)
  @browser.text_field(name: "employer_profile[fein]").set(@employer_profile.fein)
  screenshot("employer_portal_employer_search_criteria")
  @browser.button(value: /Search Employers/).fire_event("onclick")
  screenshot("employer_portal_employer_contact_info")
  @browser.button(value: /This is my employer/).fire_event("onclick")
  @browser.button(value: /Create/).wait_until_present
  @browser.button(value: /Create/).fire_event("onclick")
end

And(/^I should see a successful creation message$/) do
  Watir::Wait.until(30) { @browser.text.include?("Employer successfully created.") }
  screenshot("employer_create_success_message")
  expect(@browser.text.include?("Employer successfully created.")).to be_truthy
end

When(/^.+ click on an employer in the employer list$/) do
  @browser.a(text: /True First Inc/).wait_until_present
  @browser.a(text: /True First Inc/).click
end

Then(/^.+ should see the employer information$/) do
  @browser.text.include?("True First Inc").wait_until_present
  expect(@browser.text.include?("True First Inc")).to be_truthy
  expect(@browser.text.include?("13101 elm tree dr\nxyz\nDunwoody, GA 30027\n(303) 123-0981 x 1231")).to be_truthy
  expect(@browser.text.include?("Enrollment\nNo Plan Years Found")).to be_truthy
end

Then(/^.+ should see the employee family roster$/) do
  @browser.a(class: /interaction-click-control-add-new-employee/).wait_until_present
  screenshot("employer_census_family")
  expect(@browser.a(class: /interaction-click-control-add-new-employee/).visible?).to be_truthy
  @browser.a(class: /interaction-click-control-add-new-employee/).click
end


Then(/^.+ should see a form to enter information about employee, address and dependents details$/) do
  # Census Employee
  fill_in 'census_employee[first_name]', with: 'John'
  fill_in 'census_employee[middle_name]', with: 'K'
  fill_in 'census_employee[last_name]', with: 'Doe'
  find(:xpath, "//p[contains(., 'NONE')]").click
  find(:xpath, "//li[contains(., 'Jr.')]").click

  fill_in 'jq_datepicker_ignore_census_employee[dob]', :with => '01/01/1980'
  fill_in 'census_employee[ssn]', :with => '786120965'

  find('label[for=census_employee_gender_male]').click

  fill_in 'jq_datepicker_ignore_census_employee[hired_on]', :with => "10/10/2014"
  find(:xpath, "//label[input[@name='census_employee[is_business_owner]']]").click

  find(:xpath, "//div[div/select[@name='census_employee[benefit_group_assignments_attributes][0][benefit_group_id]']]//p[@class='label']").click
  find(:xpath, "//div[div/select[@name='census_employee[benefit_group_assignments_attributes][0][benefit_group_id]']]//li[@data-index='1']").click

  # Address
  fill_in 'census_employee[address_attributes][address_1]', :with => "1026 Potomac"
  fill_in 'census_employee[address_attributes][address_2]', :with => "Apt ABC"
  fill_in 'census_employee[address_attributes][city]', :with => "Alpharetta"

  find(:xpath, "//p[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//li[contains(., 'GA')]").click

  fill_in 'census_employee[address_attributes][zip]', :with => "30228"

  find(:xpath, "//p[contains(., 'SELECT KIND')]").click
  find(:xpath, "//li[@data-index='1'][contains(., 'home')]").click

  fill_in 'census_employee[email_attributes][address]', :with => 'trey.john@dc.gov'

  find('.form-inputs .add_fields').click

  # need to get name attribute since it's got a timestamp in it
  name = find(:xpath, "//div[@id='dependent_info']//input[@placeholder='FIRST NAME']")['name']
  fill_in name, :with => 'Mary'
  fill_in name.gsub('first', 'middle'), :with => 'K'
  fill_in name.gsub('first', 'last'), :with => 'Doe'
  fill_in name.gsub('first_name', 'ssn'), :with => '321321321'
  fill_in "jq_datepicker_ignore_#{name.gsub('first_name', 'dob')}", :with => '10/12/2012'

  find(:xpath, "//p[contains(text(), 'SELECT RELATIONSHIP')]").click
  find(:xpath, "//li[contains(text(), 'Child')]").click

  find(:xpath, "//label[@for='#{name.gsub('[', '_').gsub(']', '').gsub('first_name', 'gender_female')}']").click

  screenshot("create_census_employee_with_data")
  click_button "Create Employee"
end

And(/^.+ should see employer census family created success message$/) do
  expect(find('.alert')).to have_content('successfully')
  expect(page).to have_content('John K Doe Jr')
  screenshot("employer_census_new_family_success_message")
end

When(/^.+ clicks? on Edit family button for a census family$/) do
  click_link 'Employees'
  wait_for_ajax
  within '.census-employees-table' do
    find('.top').click
  end
  find('.fa-pencil').click
end

When(/^.+ edits? ssn and dob on employee detail page after linked$/) do
  Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.census_employees.first.link_employee_role!

  @browser.button(value: /Update Employee/).wait_until_present
  @browser.text_field(id: /jq_datepicker_ignore_census_employee_dob/).set("01/01/1981")
  @browser.text_field(id: /census_employee_ssn/).set("786120969")
  @browser.button(value: /Update Employee/).wait_until_present
  @browser.button(value: /Update Employee/).click
end


Then(/^.+ should see Access Denied$/) do
  @browser.element(text: /Access Denied!/).wait_until_present
  @browser.element(text: /Access Denied!/).visible?
end

When(/^.+ go back$/) do
  @browser.execute_script('window.history.back()')
end

Then(/^.+ should see a form to update the contents of the census employee$/) do
  #Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.census_employees.first.delink_employee_role!
  fill_in 'census_employee[first_name]', :with => 'Patrick'
  fill_in 'jq_datepicker_ignore_census_employee[dob]', :with => '01/01/1980'
  fill_in 'census_employee[ssn]', :with => '786120965'
  find('.darkblue').click
  find(:xpath, '//p[@class="label"][contains(., "GA")]').click
  find(:xpath, "//li[contains(., 'VA')]").click

  fill_in 'census_employee[census_dependents_attributes][0][first_name]', :with => "Mariah"
  find('label[for=census_employee_is_business_owner]').click

  find('.selectric-interaction-choice-control-census-employee-census-dependents-attributes-0-employee-relationship').click
  find('.label', text: 'Child').click

  screenshot("update_census_employee_with_data")
  click_button 'Update Employee'
end

And(/^.+ should see employer census family updated success message$/) do
  expect(find('.alert')).to have_content('Census Employee is successfully updated.')
end

When(/^.+ clicks on terminate button for a census family$/) do
  # ce = Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.census_employees.first.dup
  # ce.save
  @browser.a(text: /Terminate/).wait_until_present
  @browser.a(text: /Terminate/).click
  terminated_date = TimeKeeper.date_of_record + 20.days
  @browser.text_field(class: /date-picker/).set(terminated_date)
  #click submit
  @browser.h3(text: /Employee Roster/).click
  @browser.a(text: /Submit/).wait_until_present
  @browser.a(text: /Submit/).click
end

When(/^.+ clicks on terminate button for rehired census employee$/) do
  @browser.a(text: /Terminate/).wait_until_present
  @browser.execute_script("$('.interaction-click-control-terminate').last().trigger('click')")
  terminated_date = (TimeKeeper.date_of_record + 60.days).strftime("%m/%d/%Y")
  @browser.execute_script("$('.date-picker').val(\'#{terminated_date}\')")
  #click submit
  @browser.h3(text: /Employee Roster/).click
  @browser.a(text: /Submit/).wait_until_present
  @browser.a(text: /Submit/).click
end

Then(/^The census family should be terminated and move to terminated tab$/) do
  @browser.a(text: /Employees/).wait_until_present
  @browser.a(text: /Employees/).click
  @browser.radio(id: "terminated_yes").fire_event("onclick")
  @browser.a(text: /Patrick K Doe Jr/).wait_until_present
  expect(@browser.a(text: /Patrick K Doe Jr/).visible?).to be_truthy
  @browser.a(text: /Employees/).wait_until_present
  @browser.a(text: /Employees/).click
  @browser.td(text: /Employment terminated/).wait_until_present
  expect(@browser.td(text: /Employment terminated/).visible?).to be_truthy
  #@browser.a(text: /Rehire/).wait_until_present
end

And(/^.+ should see the census family is successfully terminated message$/) do
  Watir::Wait.until(30) {  @browser.text.include?("Successfully terminated family.") }
end

When(/^.+ clicks? on Rehire button for a census family on terminated tab$/) do
  # Organization.where(legal_name: 'Turner Agency, Inc').first.employer_profile.census_employees.where(aasm_state: "employment_terminated").update(name_sfx: "Sr", first_name: "Polly")
  @browser.a(text: /Rehire/).wait_until_present
  @browser.a(text: /Rehire/).click
  hired_date = (TimeKeeper.date_of_record + 30.days).strftime("%m/%d/%Y")
  #@browser.text_field(class: /hasDatepicker/).set(hired_date)
  @browser.execute_script("$('.date-picker').val(\'#{hired_date}\')")
  #click submit
  @browser.h3(text: /Employee Roster/).click
  @browser.a(text: /Submit/).wait_until_present
  @browser.a(text: /Submit/).click
end

Then(/^A new instance of the census family should be created$/) do
  @browser.a(text: /Employees/).wait_until_present
  @browser.a(text: /Employees/).click
  @browser.radio(id: "family_all").wait_until_present
  @browser.radio(id: "family_all").fire_event("onclick")
  @browser.element(text: /Rehired/).wait_until_present
  @browser.element(text: /Rehired/).visible?
  expect(@browser.a(text: /Terminate/).visible?).to be_truthy
end

And(/^.+ should see the census family is successfully rehired message$/) do
  Watir::Wait.until(30) {  @browser.text.include?("Successfully rehired family.") }
end

When(/^I go to the Profile tab$/) do
  find('.interaction-click-control-update-business-info').click
  find('.interaction-click-control-cancel').click

  expect(page).to have_content('Business Info')
end


When(/^.+ go[es]+ to the benefits tab I should see plan year information$/) do
  click_link 'Benefits'
end


And(/^.+ should see a button to create new plan year$/) do
  screenshot("employer_plan_year")
  #Hackity Hack need both years reference plans b/c of Plan.valid_shop_dental_plans and Plan.by_active_year(params[:start_on]).shop_market.health_coverage.by_carrier_profile(@carrier_profile).and(hios_id: /-01/)
  year = (Date.today + 2.months).year
  plan = FactoryGirl.create :plan, :with_premium_tables, active_year: year, market: 'shop', coverage_kind: 'health', deductible: 4000
  plan2 = FactoryGirl.create :plan, :with_premium_tables, active_year: (year - 1), market: 'shop', coverage_kind: 'health', deductible: 4000, carrier_profile_id: plan.carrier_profile_id
  find('a.interaction-click-control-add-plan-year').click
end

And(/^.+ should be able to enter plan year, benefits, relationship benefits with (high|low) FTE$/) do |amount_of_fte|
  find(:xpath, "//p[@class='label'][contains(., 'SELECT START ON')]").click
  find(:xpath, "//li[@data-index='1'][contains(., '#{(Date.today + 2.months).year}')]").click

  screenshot("employer_add_plan_year")
  find('.interaction-field-control-plan-year-fte-count').click

  if amount_of_fte == "low"
    fill_in "plan_year[fte_count]", :with => "3"
  else
    fill_in "plan_year[fte_count]", :with => "235"
  end

  fill_in "plan_year[pte_count]", :with => "15"
  fill_in "plan_year[msp_count]", :with => "3"

  find('.interaction-click-control-continue').click

  # Benefit Group
  fill_in "plan_year[benefit_groups_attributes][0][title]", :with => "Silver PPO Group"

  find('.interaction-choice-control-plan-year-start-on').click
  find('li.interaction-choice-control-plan-year-start-on-1').click

  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][0][premium_pct]", :with => 50
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][1][premium_pct]", :with => 50
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][2][premium_pct]", :with => 50
  fill_in "plan_year[benefit_groups_attributes][0][relationship_benefits_attributes][3][premium_pct]", :with => 50

  find(:xpath, '//li/label[@for="plan_year_benefit_groups_attributes_0_plan_option_kind_single_carrier"]').click
  wait_for_ajax
  find('.carriers-tab a').click
  wait_for_ajax(10,2)
  find('.reference-plans label').click
  wait_for_ajax
  find('.interaction-click-control-create-plan-year').trigger('click')
end

And(/^.+ should see a success message after clicking on create plan year button$/) do
  expect(page).to have_content('Plan Year successfully created')
  screenshot("employer_plan_year_success_message")
end

When(/^.+ enters filter in plan selection page$/) do
  find(:xpath, '//label[@class="checkbox-custom-label"][contains(., "HMO")]').click
  click_link 'Apply'
end

When(/^.+ enters? hsa_compatible filter in plan selection page$/) do
  find(:xpath, "//div[contains(@class, 'selectric-plan-carrier-selection-filter')]//p[@class='label']").trigger 'click'
  find(:xpath, "//div[contains(@class, 'selectric-plan-carrier-selection-filter')]//li[contains(@class, 'interaction-choice-control-carrier-1')]").trigger 'click'

  find(:xpath, "//div[contains(@class, 'selectric-plan-hsa-eligibility-selection-filter')]//p[@class='label']").trigger 'click'
  find(:xpath, "//div[contains(@class, 'selectric-plan-hsa-eligibility-selection-filter')]//li[contains(@class, 'interaction-choice-control-carrier-0')]").trigger 'click'

  click_link 'Apply'
end

When(/^.+ enters? combined filter in plan selection page$/) do
  find(:xpath, "//label[@for='plan-metal-level-silver']").click
  find(:xpath, '//label[@class="checkbox-custom-label"][contains(., "HMO")]').click

  find('.plan-metal-deductible-from-selection-filter').set("1000")
  find('.plan-metal-deductible-to-selection-filter').set("5500")

  click_link 'Apply'
end

Then(/^.+ should see the hsa_compatible filter results$/) do
  expect(find('.plan-row')).to have_content('BlueChoice Silver')
end

Then(/^.+ should see the combined filter results$/) do
  expect(find('.plan-row')).to have_content('BlueChoice Silver')
end

When(/^.+ go(?:es)? to the benefits tab$/) do
  find(".interaction-click-control-benefits").click
end

Then(/^.+ should see the plan year$/) do
  expect(page).to have_css('.interaction-click-control-publish-plan-year')
end

When(/^.+ clicks? on publish plan year$/) do
  find('.interaction-click-control-publish-plan-year').click
end

Then(/^.+ should see Publish Plan Year Modal with warnings$/) do
  expect(find('.modal-body')).to have_content('Number of full time equivalents (FTEs) exceeds maximum allowed')
end

Then(/^.+ clicks? on the Cancel button$/) do
  find(".modal-dialog .interaction-click-control-cancel").click
end

Then(/^.+ should be on the Plan Year Edit page with warnings$/) do
  expect(page).to have_css('#plan_year')
  expect(find('.alert-plan-year')).to have_content('Number of full time equivalents (FTEs) exceeds maximum allowed')
end

Then(/^.+ updates? the FTE field with valid input and save plan year$/) do
  fill_in 'plan_year[fte_count]', :with => '10'
  find('.interaction-click-control-save-plan-year').click
end

Then(/^.+ should see a plan year successfully saved message$/) do
  expect(find('.alert')).to have_content('Plan Year successfully saved')
end

When(/^.+ clicks? on employer my account link$/) do
  click_link 'My DC Health Link'
end

Then(/^.+ should see employee cost modal for current plan year$/) do
  find('a.interaction-click-control-employee-detail-costs').click
  expect(page).to have_css('h4.modal-title')
  find('.close').click
end


module EmployeeWorld
  def owner(*traits)
    attributes = traits.extract_options!
    @owner ||= FactoryGirl.create :user, *traits, attributes
  end

  def employer(*traits)
    attributes = traits.extract_options!
    @employer ||= FactoryGirl.create :employer, *traits, attributes
  end

  def employees(*traits)
    attributes = traits.extract_options!
    @employees ||= FactoryGirl.create_list :census_employee, 5, *traits, attributes
    # :employer_profile, *traits, attributes.merge(:employer_profiles_traits => :with_staff)
  end
end
World(EmployeeWorld)

Given /^an employer exists$/ do
  owner :with_family, :employer, organization: employer
end

When /^they visit the Employee Roster$/ do
  visit employers_employer_profile_path(employer.employer_profile) + "?tab=employees"
end

When /^click on one of their employees$/ do
  click_link employees.first.full_name
end

Given /^the employer has employees$/ do
  employees employer_profile: employer.employer_profile
end

Given /^the employer is logged in$/ do
  login_as owner, scope: :user
end

And /^clicks on terminate employee$/ do
  expect(page).to have_content 'Employee Roster'
  employees.first
  first(".fa-trash-o").click
  terminate_date = (TimeKeeper.date_of_record - 10.days).strftime("%m/%d/%Y")
  page.execute_script("$('.date-picker').val(\'#{terminate_date}\')")
  find('.interaction-click-control-terminate-employee').click
  expect(page).to have_content 'Employee Roster'
  wait_for_ajax(2,2)
end

Then /^employer clicks on terminated filter$/ do
  expect(page).to have_content "Select 'Add New Employee' to continue building your roster, or select 'Upload Employee Roster' if you're ready to download or upload the roster template"
  find('.filter').click
  wait_for_ajax
  page.execute_script("$('.filter-options').show();")
  find("#terminated_yes").trigger('click')
end

Then /^employer sees termination date column$/ do
  expect(page).to have_content 'Termination Date'
end

And /^employer clicks on terminated employee$/ do
  expect(page).to have_content "Eddie Vedder"
  find(:xpath, '//*[@id="home"]/div/div/div[2]/div[2]/div/div[2]/div[2]/div/div[1]/table/tbody/tr[1]/td[1]/a').click
end

And /^employer clicks on back button$/ do
  expect(page).to have_content "Details"
  find('.interaction-click-control-back-to-employee-roster-\(terminated\)').click
end

Then /^employer should see employee roaster$/ do
  expect(page).to have_content "Employee Roster"
end
And /^employer should also see termination date$/ do
  expect(page).to have_content "Termination Date"
end

And /^employer clicks on all employees$/ do
  expect(page).to have_content "Select 'Add New Employee' to continue building your roster, or select 'Upload Employee Roster' if you're ready to download or upload the roster template"
  find('.filter').click
  wait_for_ajax
  page.execute_script("$('.filter-options').show();")
  find("#family_all").trigger('click')
end

And /^employer clicks on cancel button$/ do
  expect(page).to have_content "Details"
  find('.interaction-click-control-cancel').click
end

Then /^employer should not see termination date column$/ do
  wait_for_ajax
  expect(page).not_to have_content "Termination Date"
end

Then /^they should see that employee's details$/ do
  wait_for_ajax
  expect(page).to have_selector("input[value='#{employees.first.dob.strftime('%m/%d/%Y')}']")
end

require 'watir'
require 'pry'
# load Rails.root + "db/seeds.rb"

module WatirScreenshots
  def screenshot(name = nil)
    if @take_screens
      shot_count = @screen_count.to_s.rjust(3, "0")
      f_name = name.nil? ? shot_count : "#{shot_count}_#{name}"
      @browser.screenshot.save("tmp/#{f_name}.png")
      @screen_count = @screen_count + 1
    end
  end
end

Before "@screenshots" do
  @take_screens = true
end

Before "@keep_browser_open" do
  @keep_browser_open = true
end

Before "@watir" do
  extend WatirScreenshots
  @browser = Watir::Browser.new :chrome, switches: ["--test-type"]
  @screen_count = 0
end

After "@watir" do
   @keep_browser_open ? @keep_browser_open = false : @browser.close
   @take_screens = false if @take_screens
end

Given(/^I do not exist as a user$/) do
end

Given(/^I have an existing employee record$/) do
end

Given(/^I have an existing person record$/) do
end

When(/^I go to the employee account creation page$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: "Employee Portal").wait_until_present
  screenshot("start")
  @browser.a(text: "Employee Portal").click
  @browser.a(text: "Create account").wait_until_present
  screenshot("employee_portal")
  @browser.a(text: "Create account").click
end

When(/^I enter my new account information$/) do
  @browser.text_field(name: "user[password_confirmation]").wait_until_present
  screenshot("create_account")
  @email = "swhite#{rand(100)}@example.com"
  @browser.text_field(name: "user[email]").set(@email)
  @browser.text_field(name: "user[password]").set("12345678")
  @browser.text_field(name: "user[password_confirmation]").set("12345678")
  @browser.input(value: "Create account").click
end

Then(/^I should be logged in$/) do
  @browser.a(href: /consumer.employee.search/).wait_until_present
  screenshot("logged_in_welcome")
  expect(@browser.a(href: /consumer.employee.search/).visible?).to be_truthy
end

When(/^I go to register as an employee$/) do
  expect(@browser.a(text: "Continue").visible?).to be_truthy
  @browser.a(text: "Continue").click
end

Then(/^I should see the employee search page$/) do
  @browser.text_field(name: "person[first_name]").wait_until_present
  screenshot("employer_search")
  expect(@browser.text_field(name: "person[first_name]").visible?).to be_truthy
end

When(/^I enter the identifying info of my existing person$/) do
  @browser.text_field(name: "person[first_name]").set("Soren")
  @browser.text_field(name: "person[last_name]").set("White")
  @browser.text_field(name: "person[date_of_birth]").set("08/13/1979")
  @browser.label(:text=> /FIRST NAME/).click
  @browser.text_field(name: "person[ssn]").set("670991234")
  screenshot("information_entered")
  @browser.button(value: /Search Employers/).wait_until_present
  @browser.button(value: /Search Employers/, :type => "submit").click
end
# TODO: needs to be merged
When(/^I enter the identifying information of my existing person$/) do
  @browser.text_field(name: "person[first_name]").set("Patrick")
  @browser.text_field(name: "person[last_name]").set("Doe")
  @browser.text_field(name: "person[date_of_birth]").set("10/10/1980")
  @browser.label(:text=> /FIRST NAME/).click
  @browser.text_field(name: "person[ssn]").set("786120965")
  screenshot("information_entered")
  @browser.button(text: "Search Employers").wait_until_present
  @browser.button(text: "Search Employers").click
end

Then(/^I should see the matched employee record form$/) do
  @browser.dd(text: /Acme Inc\./).wait_until_present
  screenshot("employer_search_results")
  expect(@browser.dd(text: /Acme Inc\./).visible?).to be_truthy
end
# TODO: needs to be merged
Then(/^I should see the matching employee record form$/) do
  @browser.dd(text: /Turner Brokers/).wait_until_present
  screenshot("employer_search_results")
  expect(@browser.dd(text: /Turner Brokers/).visible?).to be_truthy
end

When(/^I accept the matched employer$/) do
  @browser.input(value: /This is my employer/).click
  @browser.input(name: "person[emails_attributes][0][address]").wait_until_present
  screenshot("update_personal_info")
end

When(/^I complete the matched employee form$/) do
  @browser.text_field(name: "person[phones_attributes][0][full_phone_number]").set("2025551234")
  @browser.text_field(name: "person[emails_attributes][1][address]").click
  screenshot("personal_info_complete")
  @browser.button(class: "btn-primary", :text => /Continue/).click
end
# TODO: needs to be merged
When(/^I complete the matching employee form$/) do
  @browser.text_field(name: "person[addresses_attributes][0][address_1]").set("84 I st")
  @browser.text_field(name: "person[addresses_attributes][0][address_2]").set("Suite 201")
  @browser.text_field(name: "person[addresses_attributes][0][city]").set("Herndon")
  @browser.text_field(name: "person[addresses_attributes][0][state]").set("VA")
  @browser.text_field(name: "person[addresses_attributes][0][zip]").set("20171")

  @browser.text_field(name: "person[phones_attributes][0][full_phone_number]").set("2025551234")
  @browser.text_field(name: "person[emails_attributes][1][address]").click
  screenshot("personal_info_complete")
  @browser.input(id: "continue-employer").click
end


Then(/^I should see the dependents page$/) do
  @browser.a(text: /Add Member/).wait_until_present
  screenshot("dependents_page")
  expect(@browser.a(text: /Add Member/).visible?).to be_truthy
end

When(/^I click edit on baby Soren$/) do
  @browser.span(text: "07/03/2014").as(xpath: "./preceding::a[contains(@href, 'edit')]").last.click
end

Then(/^I should see the edit dependent form$/) do
  @browser.button(:text => /Confirm Member/).wait_until_present
end

When(/^I click delete on baby Soren$/) do
  @browser.form(id: 'edit_dependent').a().click
  @browser.button(text: /Confirm Member/).wait_while_present
end

Then(/^I should see (.*) dependents$/) do |n|
  n = n.to_i
  expect(@browser.li(class: "dependent_list", index: n)).not_to exist
  expect(@browser.li(class: "dependent_list", index: n - 1)).to exist
end

When(/^I click Add Member$/) do
  @browser.a(text: /Add Member/).click
  @browser.button(text: /Confirm Member/).wait_until_present
end

Then(/^I should see the new dependent form$/) do
  expect(@browser.button(text: /Confirm Member/).visible?).to be_truthy
end

When(/^I enter the identifying info of Sorens daughter$/) do
  @browser.text_field(name: 'dependent[first_name]').set('Cynthia')
  @browser.text_field(name: 'dependent[last_name]').set('White')
  @browser.text_field(name: 'dependent[date_of_birth]').set('01/15/2011')
  @browser.label(text: /FIRST NAME/).click
  @browser.text_field(name: 'dependent[relationship]').set('child')
  @browser.input(type: 'radio', value: 'female').click
end

When(/^I click confirm member$/) do
  @browser.button(text: /Confirm Member/).click
  @browser.button(text: /Confirm Member/).wait_while_present
end

When(/^I click continue on the dependents page$/) do
  @browser.a(text: "Continue", :href => /group_selection\/new/).click
end

Then(/^I should see the group selection page$/) do
  @browser.form(action: /group_selection\/create/).wait_until_present
  screenshot("group_selection")
end

When(/^I click continue on the group selection page$/) do
  @browser.button(class: "btn-primary", text: /Continue/).click
end

Then(/^I should see the plan shopping welcome page$/) do
  @browser.element(text: /All Filters/i).wait_until_present
  # @browser.h3(text: /Select a Plan/).wait_until_present
  screenshot("plan_shopping_welcome")
  expect(@browser.element(text: /All Filters/i).visible?).to be_truthy
  # expect(@browser.h3(text: /Select a Plan/).visible?).to be_truthy
end

When(/^I click continue on the plan shopping welcome page$/) do
  @browser.a(text: "Continue").click
end

Then(/^I should see the list of plans$/) do
  @browser.a(text: /Select/).wait_until_present
  screenshot("plan_shopping")
end

When(/^I select a plan on the plan shopping page$/) do
  @browser.a(text: /Select/).click
end

Then(/^I should see the coverage summary page$/) do
  @browser.a(href: /plan_shoppings/, class: "btn-continue").wait_until_present
  screenshot("summary_page")
  expect(@browser.a(href: /plan_shoppings/, class: "btn-continue").visible?).to be_truthy
end

When(/^I confirm on the coverage summary page$/) do
  @browser.a(href: /insured.plan_shoppings.(.*).checkout/).wait_until_present
  @browser.a(href: /insured.plan_shoppings.(.*).checkout/).fire_event("onclick")
end

Then(/^I should see the "my account" page$/) do
  @browser.element(text: /Life Events/).wait_until_present
  screenshot("my_account_page")
  expect(@browser.element(text: /Life Events/).visible?).to be_truthy
end

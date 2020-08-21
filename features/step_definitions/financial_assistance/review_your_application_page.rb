# frozen_string_literal: true

And(/^all applicants are in Info Completed state with all types of income$/) do
  application.update_attributes!(aasm_state: "draft", attestation_terms: true, parent_living_out_of_home_terms: true, medicaid_terms: true, submission_terms: true, medicaid_insurance_collection_terms: true, report_change_terms: true)
  application.primary_applicant.update_attributes(is_former_foster_care: false, has_daily_living_help: false, need_help_paying_bills: false, is_ssn_applied: true, is_required_to_file_taxes: true, is_claimed_as_tax_dependent: false, has_job_income: true, has_deductions: true, has_eligible_health_coverage: true, has_self_employment_income: false, has_other_income: false, has_enrolled_health_coverage: false, is_pregnant: false, is_self_attested_blind: false, is_post_partum_period: false)

  application.primary_applicant.incomes.create(title: "Income", amount: 40_000, kind: "wages_and_salaries", frequency_kind: "yearly", start_on: TimeKeeper.date_of_record - 1.year).save
  application.primary_applicant.incomes.first.employer_address = Address.new(kind: "work", address_1: "123 fake st", city: "Washington", state: "DC", zip: '20002')
  application.primary_applicant.incomes.first.employer_phone = Phone.new(kind: "work", area_code: '123', number: '4567890', full_phone_number: "123-456-7890", extension: "+1")

  application.primary_applicant.benefits.create(title: "Benefit", kind: "is_eligible", insurance_kind: "medicaid").save
  application.primary_applicant.deductions.create(title: "Deduction", amount: 4000, kind: "health_savings_account", frequency_kind: "yearly", start_on: TimeKeeper.date_of_record - 1.year).save
end

And(/^the user does not see Info Needed$/) do
  expect(page).not_to have_content("Info Needed")
end

Given(/^the user is on the Review Your Application page$/) do
  expect(page).to have_content("Review Your Application")
end

Then(/^the user visits the Review Your Application page$/) do
  application.update_attributes!(aasm_state: "draft")
  visit financial_assistance.review_and_submit_application_path id: application.id.to_s
  expect(page).to have_content("Review Your Application")
end


Given(/^the pencil icon displays for each instance of (.*?)$/) do |instance_type|
  type = instance_type.downcase.gsub(" ", "-")
  expect(page).to have_selector(:id, "edit-#{type}-pencil")
end


And(/^the user clicks the pencil icon for (.*?)$/) do |icon_type|
  type = icon_type.downcase.gsub(" ", "-")
  find("#edit-#{type}-pencil").click
end


Then(/^the user should navigate to the (.*?) page$/) do |page|
  expect(page).to have_content(page)
end


Given(/^the user views the (.*?) row$/) do |row_type|
  expect(page).to have_content(row_type)
end


When(/^the user clicks the applicant's pencil icon for (.*?)$/) do |icon_type|
  type = icon_type.downcase.gsub(" ", "-")
  find("#edit-#{type}-pencil").click
end


And(/^all data should be presented as previously entered$/) do
  if page.has_css?('h2', text: 'Tax Info')
    expect(find('#is_required_to_file_taxes_yes')).to be_checked
    expect(find('#is_claimed_as_tax_dependent_no')).to be_checked
  elsif page.has_css?('h2', text: 'Job Income')
    expect(find('#has_job_income_true')).to be_checked
    expect(find('#has_self_employment_income_false')).to be_checked
  elsif page.has_css?('h2', text: 'Other Income')
    expect(find('#has_other_income_false')).to be_checked
  elsif page.has_css?('h2', text: 'Income Adjustments')
    expect(find('#has_deductions_true')).to be_checked
    expect(find('.deduction-checkbox-health_savings_account')).to be_checked
  elsif page.has_css?('h2', text: 'Health Coverage')
    expect(find('#has_enrolled_health_coverage_false')).to be_checked
    expect(find('#has_eligible_health_coverage_true')).to be_checked
  elsif page.has_css?('h2', text: 'Other Questions')
    expect(find('#is_pregnant_no')).to be_checked
    expect(find('#is_self_attested_blind_no')).to be_checked
    expect(find('#has_daily_living_no')).to be_checked
    expect(find('#need_help_paying_bills_no')).to be_checked
  end
end


And(/^the CONTINUE button is enabled$/) do
  expect(page.find('#btn-continue')[:class]).not_to include("disabled")
end

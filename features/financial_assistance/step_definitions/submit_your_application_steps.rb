Then(/^the user is on the Submit Your Application page$/) do
  expect(page).to have_content("Submit Your Application")
end

Given(/^a required checkbox is not checked$/) do
  expect(find_all("input[type='checkbox']").any? { |checkbox| !checkbox.checked? }).to be(true)
end

Given(/^the applicant has not signed their name$/) do
  expect(true).to eq(find("#first_name_thank_you").text.empty?).or eq(find("#last_name_thank_you").text.empty?)
end

Then(/^the submit button will be disabled$/) do
  expect(find(".interaction-click-control-submit-application")[:class].include?("disabled")).to be(true)
end

Given(/^all required checkboxes are checked$/) do
   find_all("input[type='checkbox']").each { |checkbox| checkbox.set(true) }
end

Given(/^the applicant has signed their name$/) do
  fill_in "first_name_thank_you", with: application.primary_applicant.person.first_name
  fill_in "last_name_thank_you", with: application.primary_applicant.person.last_name
end

Then(/^the submit button will be enabled$/) do
	expect(find(".interaction-click-control-submit-application")[:class].include?("disabled")).to be(false)
end

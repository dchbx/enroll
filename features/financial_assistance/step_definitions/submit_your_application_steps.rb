Then(/^the user is on the Submit Your Application page$/) do
  expect(page).to have_content("Submit Your Application")
end

Given(/^a required question is not answered$/) do
  expect(find_all("input[type='checkbox']").any? { |checkbox| !checkbox.checked? }).to be(true)
  expect(false).to eq(find("#living_outside_no").checked?).and eq(find("#living_outside_yes").checked?)
end

Given(/^the user has not signed their name$/) do
  expect(true).to eq(find("#first_name_thank_you").text.empty?).or eq(find("#last_name_thank_you").text.empty?)
end

Then(/^the submit button will be disabled$/) do
  expect(find(".interaction-click-control-submit-application")[:class].include?("disabled")).to be(true)
end

Given(/^all required questions are answered$/) do
  find_all("input[type='checkbox']").each { |checkbox| checkbox.set(true) }
  find("#living_outside_no").set(true)
end

Given(/^the user has signed their name$/) do
  fill_in "first_name_thank_you", with: application.primary_applicant.person.first_name
  fill_in "last_name_thank_you", with: application.primary_applicant.person.last_name
end

Then(/^the submit button will be enabled$/) do
	expect(find(".interaction-click-control-submit-application")[:class].include?("disabled")).to be(false)
end

Then(/^the user is on the Error Submitting Application page$/) do
	expect(page).to have_content("Error Submitting Application")
end

Given(/^the user clicks SUBMIT$/) do
  find(".interaction-click-control-submit-application").click
end

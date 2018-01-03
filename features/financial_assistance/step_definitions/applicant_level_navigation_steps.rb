When(/^the user clicks ADD\/EDIT INCOME & COVERAGE INFO button for a given household member$/) do
  click_link 'ADD INCOME & COVERAGE INFO'
end

When(/^applicant should see and confirm modal dialog box$/) do
  expect(page).to have_content('Unsaved Tax Info Changes')
  click_button "Continue"
end
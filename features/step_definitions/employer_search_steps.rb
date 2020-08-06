# frozen_string_literal: true

When(/^the user enters fein of employer ABC Widgets in search bar$/) do
  find("input[type=search]").set(employer("XYZ Widgets").fein)
end

Then(/^the user will see ABC Widgets Employer$/) do
  expect(page).to have_content(employer("ABC Widgets").fein)
  expect(page).to have_content(employer("ABC Widgets").legal_name.titleize)
end

Then(/^the user will not see XYZ Widgets Employer$/) do
  expect(page).not_to have_content(employer("XYZ Widgets").fein)
  expect(page).not_to have_content(employer("XYZ Widgets").legal_name.titleize)
end

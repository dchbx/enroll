Given(/^all plan shopping are of mixed determination$/) do
  create_mixed_eligibilty_for_the_family
end

Then(/^selects a csr plan$/) do
  find(:xpath, "//*[@id='plans']/div[1]/div/div[5]/div[3]/a[1]").click
end

Then(/^the page should redirect to thankyou page$/) do
  expect(page).to have_text('Confirm Your Plan Selection')
  expect(page).to have_text('You must complete these steps to enroll.')
end

Given(/^the page should not have any csr plans$/) do
  expect(page).not_to have_css('.fa-check-square')
end

When(/^csr plans exists in db$/) do
  update_a_standard_plan_to_be_csr
end


When(/^the db has standard plans$/) do
  reset_plans_to_be_standard
end

Then(/^selects a non csr plan$/) do
  find(:xpath, "//*[@id='plans']/div[2]/div/div[5]/div[3]/a[1]").click
end

Then(/^the page should open a model pop-up for confirmation$/) do
  expect(page).to have_text('You are Eligible for Lower Costs')
  expect(page).to have_text('You are eligible for cost-sharing reductions, but can only use this benefit if you enroll in a silver plan.')
end

Then(/^user clicks close button$/) do
  find(".close").click
end

Then(/^the page should have csr plans$/) do
  expect(page).to have_css('.fa-check-square')
end

Given(/^every individual is eligible for Plan shopping for CSR plans$/) do
  create_aptc_only_eligibilty_for_the_family
end


Then (/^Hbx Admin sees Families link$/) do
  expect(page).to have_text("Families")
end

When(/^Hbx Admin clicks on Families link$/) do
  click_link "Families"
  wait_for_ajax
  find(:xpath, "//*[@id='myTab']/li[2]/ul/li[1]/a/span[1]", :wait => 10).click
  wait_for_ajax
end

Then(/^Hbx Admin should see an Edit APTC \/ CSR link$/) do
  find_link('Edit APTC / CSR').visible?
end

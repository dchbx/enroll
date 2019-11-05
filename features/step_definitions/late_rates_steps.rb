Given(/^employer ABC Widgets visits benefits page$/) do
  visit "/"
  find(:xpath, '//*[@id="welcome-nav-options"]/div/a[5]').click
  find(:xpath, '//*[@id="uic-employers-right-menu"]/li[3]/a').click
end

And(/^Employer doesn't have benefit applications$/) do
  expect(page).to have_no_content("Edit Plan Year")
end

When(/^Employer clicks on Add PlanYear button$/) do
  click_link 'Add Plan Year'
end

Then(/^Employer should see shell plan year page$/) do
  expect(page).to have_content("Add Benefit Package")
end

And(/^Employer clicks on all valid information$/) do
  find(:xpath, '//*[@id="uic-wrapper"]/div[1]/div/div[2]/span').click
  expect(page).to have_content((TimeKeeper.date_of_record.beginning_of_month + 2.months).strftime("%m/%d/%Y"))
  find('li', :text => "#{(TimeKeeper.date_of_record.beginning_of_month + 2.months).strftime('%m/%d/%Y')}").click

  find('#fteEmployee').click
  fill_in 'benefit_application[fte_count]', :with => 10

  find('#pteEmployee').click
  fill_in 'benefit_application[pte_count]', :with => 3

  find('#medSecPayers').click
  fill_in 'benefit_application[msp_count]', :with => 3


end

When(/^Employer clicks on Continue Button$/) do
  #expect(page).to have_content("#{Settings.site.late_rates_message}")
  #click_link 'CONTINUE'
  #find(:xpath, '//*[@id="benefitContinueBtn"]').click
  #expect(page).to have_content("CONTINUE")
  find(".broker-registration", wait: 10).click
end

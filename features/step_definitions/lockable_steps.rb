Then(/^there are (\d+) preloaded (.*?) user accounts$/) do |num, status|
  (0...num.to_i).each do |int|
    user = FactoryGirl.create(:user, :with_family)
    user.lock! if status.eql?('locked')
  end
end

Then(/^Hbx Admin should see Unlock\/Lock Account link$/) do
  find_link('Unlock / Lock Account').visible?
end

When(/^Hbx Admin clicks on Unlock\/Lock Account link$/) do
  click_link('Unlock / Lock Account')
  wait_for_ajax
end

Then(/^there is a confirm link on in the list$/) do
  find_link('Confirm').visible?
end

When(/^I click on the confirm link$/) do
  page.all('.child-row').last.should(have_content('Confirm'))
  wait_for_ajax
end

Then(/^the locked user should be in the list$/) do
  page.all('table.effective-datatable tbody tr').last.should(have_content('Locked'))
end

# frozen_string_literal: true

When(/^I see the (.*?) link$/) do |method|
  find_link(method)
end

Then(/^the Paper action should not be actionable$/) do
  find(:xpath, "//*[@id='myTab']/li[2]/ul/li[6]")['class'].split(' ')[1] == 'blocking'
end

# frozen_string_literal: true

And(/^.+ clicks on Families tab$/) do
  find(:xpath, '//a[@class="interaction-click-control-families"]', :wait => 10).click
end

And(/^.+ clicks on the name of person (.*?) from family index_page$/) do |person_name|
  find('a', :text => person_name).click
end

And(/^.+ clicks on the Manage Family button$/) do
  find('a.interaction-click-control-manage-family', :wait => 10).click
end

And(/^.+ clicks on the Personal portal/) do
  find('a.interaction-click-control-personal', :wait => 10).click
end

Then(/^.+ will see the Ageoff Exclusion checkbox$/) do
  expect(page).to have_content("Ageoff Exclusion")
end

And(/^.+ clicks on the Family portal$/) do
  find('a.interaction-click-control-family', :wait => 10).click
end

And(/^.+ clicks on Add Member$/) do
  find(:xpath, '//*[@id="add-member-btn"]/a', :wait => 10).click
end
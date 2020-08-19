Given(/^at least two other household members exist$/) do
  click_link "Add New Person"
  fill_in "dependent_first_name", with: 'johnson'
  fill_in "dependent_last_name", with: 'smith'
  fill_in "family_member_dob_", with: '10/10/1984'
  fill_in "dependent_ssn", with: '123456543'
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '/html/body/div[2]/div[2]/div/div[2]/div[1]/div[5]/ul/li/div/form/div[1]/div[5]/div[2]/div[2]/div/div[2]/p').click
  find(:xpath, '/html/body/div[2]/div[2]/div/div[2]/div[1]/div[5]/ul/li/div/form/div[1]/div[5]/div[2]/div[2]/div/div[3]/div/ul/li[7]').click
  find(:xpath, '//label[@for="is_applying_coverage_false"]').click
  find(".btn", text: "CONFIRM MEMBER").click

  click_link "Add New Person"
  fill_in "dependent_first_name", with: 'smity'
  fill_in "dependent_last_name", with: 'johnson'
  fill_in "family_member_dob_", with: '10/10/1964'
  fill_in "dependent_ssn", with: '123456549'
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '/html/body/div[2]/div[2]/div/div[2]/div[1]/div[5]/ul/li/div/form/div[1]/div[5]/div[2]/div[2]/div/div[2]/p').click
  find(:xpath, '/html/body/div[2]/div[2]/div/div[2]/div[1]/div[5]/ul/li/div/form/div[1]/div[5]/div[2]/div[2]/div/div[3]/div/ul/li[7]').click
  find(:xpath, '//label[@for="is_applying_coverage_false"]').click
  find(".btn", text: "CONFIRM MEMBER").click
  
  expect(page).to have_content('ADD INCOME & COVERAGE INFO', count: 3)
end

Given(/^that the user is on the FAA Family Relationships page$/) do
  page.should have_xpath('//*[@id="family-matrix"]/h1')
end


Then(/^View My Applications left section WILL display$/) do
  expect(page).to have_content('View My Applications')
end

Then(/^Review & Submit left section WILL display$/) do
  expect(page).to have_content('Review & Submit')
end

Given(/^there is a nil value for at least one relationship$/) do
  expect(find_all(:css, ".selectric .label").map{ |selector| selector.text }).to include("")
end

Then(/^the family member row will be highlighted$/) do
  expect(page).to have_css('.missing_relation')
end


When(/^the user populates the drop down with a value$/) do
  @relationship = find_all(:css, ".missing_relation").first
  @relationship.find(:xpath, 'div/div[2]/div[2]/div[2]/div/div[3]/div/ul/li[7]', :visible => false).trigger('click')
end


Then(/^the relationship is saved$/) do
  expect(@relationship.find(:css, ".selectric .label").text).to eq("Unrelated")
end

Given(/^all the relationships have been entered$/) do
  find_all(:css, ".missing_relation").each {|relation| 
    relation.find(:xpath, 'div/div[2]/div[2]/div[2]/div/div[3]/div/ul/li[7]', :visible => false).trigger('click')
  }
  find_all(:css, ".selectric .label").each{ |selector| 
    expect(selector.text).to eq("Unrelated")
  }
  expect(page).to have_no_css('.missing_relation')
end



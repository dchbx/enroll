Given(/^all applicants are in Info Completed state with all types of income$/) do
 while find_all(".btn", text: "ADD INCOME & COVERAGE INFO").length > 0 do  
    find_all(".btn", text: "ADD INCOME & COVERAGE INFO")[0].click
    find("#is_required_to_file_taxes_no").click
    find("#is_claimed_as_tax_dependent_no").click
    find(:xpath, "//input[@value='CONTINUE'][@name='commit']").click
      
    find("#has_job_income_true").click
    fill_in 'financial_assistance_income[employer_name]', with: 'GloboGym'
    fill_in 'financial_assistance_income[amount]', with: '100'
    fill_in 'financial_assistance_income[start_on]', with: '1/1/2018'
    find(:xpath, '//*[@id="new_financial_assistance_income"]/div[1]/div[2]/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_financial_assistance_income"]/div[1]/div[2]/div[2]/div/div[3]/div/ul/li[2]').click
    fill_in 'financial_assistance_income[employer_address][address_1]', with: '1 K Street'
    fill_in 'financial_assistance_income[employer_address][city]', with: 'Washington'
    fill_in 'financial_assistance_income[employer_address][zip]', with: '20000'
    find(:xpath, '//*[@id="new_financial_assistance_income"]/div[1]/div[4]/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_financial_assistance_income"]/div[1]/div[4]/div[2]/div/div[3]/div/ul/li[10]').click
    fill_in 'financial_assistance_income[employer_phone][full_phone_number]', with: '7898765676'
    click_button('Save')
    find("#has_self_employment_income_true").click   
    fill_in 'financial_assistance_income[amount]', with: '100.00'
    find(:xpath, '//*[@id="new_financial_assistance_income"]/div[1]/div/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_financial_assistance_income"]/div[1]/div/div[2]/div/div[3]/div/ul/li[3]').click
    fill_in 'financial_assistance_income[start_on]', with: '01/01/2018'
    click_button('Save')
    find(:xpath, '//*[@id="btn-continue"]').click

    find("#has_other_income_true").click
    find(:css, "#other_income_kind[value='interest']").set(true)
    fill_in 'financial_assistance_income[amount]', with:'100'
    fill_in 'financial_assistance_income[start_on]', with:'1/1/2018'
    find(:xpath, '//*[@id="new_financial_assistance_income"]/div/div[1]/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_financial_assistance_income"]/div/div[1]/div[2]/div/div[3]/div/ul/li[3]').click
    click_button("Save")
    find(:xpath, '//*[@id="btn-continue"]').click
  
    find("#has_deductions_true").click
    find(:css, "#deduction_kind[value='moving_expenses']").set(true)
    fill_in 'financial_assistance_deduction[amount]', with: '50'
    fill_in 'financial_assistance_deduction[start_on]', with:'1/1/2018'
    find(:xpath, '//*[@id="new_financial_assistance_deduction"]/div/div[1]/div[2]/div/div[2]/b').click
    find(:xpath, '//*[@id="new_financial_assistance_deduction"]/div/div[1]/div[2]/div/div[3]/div/ul/li[5]').click
    click_button("Save")
    find(:xpath, '//*[@id="btn-continue"]').click
    
    find("#has_enrolled_health_coverage_false").click
    find("#has_eligible_health_coverage_false").click


    find(:xpath, '//*[@id="btn-continue"]').click
  
    find("#is_pregnant_no").click
    find("#is_post_partum_period_no").click
    find("#is_self_attested_blind_no").click
    find("#has_daily_living_no").click
    find("#need_help_paying_bills_no").click
    find("#radio_physically_disabled_no").click
    find('[name=commit]').click       
  end
end

Then(/^the user is on the Review Your Application page$/) do
  expect(page).to have_content("Review Your Application")
end

Given(/^the pencil icon displays for each instance of (.*)$/) do |deduction|
  find_all(:xpath, '//*[@id="dependents_info_wrapper"]/div[1]/div/table//tr').each{ |tr|
    unless tr[:class].eql?("form-heading")
      expect(tr).to have_css('.fa-pencil')
    end
  }
end

Then(/^the user clicks the pencil icon for (.*)$/) do |type|
  if type.eql?("Wages and salaries") || type.eql?("Self Employment Income") 
    find(:xpath, '//*[@id="dependents_info_wrapper"]/div[1]/div/table/tbody/tr[1]/td[5]/span/a').click
  elsif type.eql?("Other Income") 
    find(:xpath, '//*[@id="dependents_info_wrapper"]/div[1]/div/table/tbody/tr[3]/td[5]/span/a').click
  elsif type.eql?("Income Adjustments")
    find(:xpath, '//*[@id="dependents_info_wrapper"]/div[1]/div/table/tbody/tr[4]/td[5]/span/a').click
  end
  sleep(5)
end


Then(/^the user should navigate to the (.*) page$/) do |type|
    type << " for" unless type.eql?("Your Preferences") || type.eql?("Submit Your Application")
    expect(page).to have_content("#{type}")
end

Then(/^the TO date label should be "([^"]*)"$/) do |expected|
 expect(page).to have_content(expected)
end

Given(/^the user views the (.*) row$/) do |type|
  find_all(:css, 'row', :text => type).length > 0
end


Then(/^the user clicks the applicant's pencil icon for (.*)$/) do |type|
  if type.eql?("TAX INFO")
    find(:xpath, '//*[@id="dependents_info_wrapper"]/div[2]/div/div[3]/div[1]/div[2]/a').click
  elsif type.eql?("Income") || type.eql?("Self Employment Income") 
    find(:xpath, '//*[@id="dependents_info_wrapper"]/div[2]/div/div[3]/div[4]/div[2]/a').click
  elsif type.eql?("Income Adjustments")
    find(:xpath, '//*[@id="dependents_info_wrapper"]/div[2]/div/div[3]/div[8]/div[2]/a').click
  elsif type.eql?("Health Coverage")
    find(:xpath, '//*[@id="dependents_info_wrapper"]/div[2]/div/div[3]/div[10]/div[2]/a').click  
  elsif type.eql?("Other Questions")
    find(:xpath, '//*[@id="dependents_info_wrapper"]/div[2]/div/div[4]/div[2]/a').click
  end
  sleep(10)
end

Then(/^all data should be presented as previously entered$/) do
  if /incomes$/.match(current_path)
    expect(find("#has_job_income_true")).to be_checked
    expect(find("#has_self_employment_income_true")).to be_checked
  elsif /step\/1$/.match(current_path)
    expect(find("#is_required_to_file_taxes_no")).to be_checked
    expect(find("#is_claimed_as_tax_dependent_no")).to be_checked
  elsif /other$/.match(current_path)
    expect(find("#has_other_income_true")).to be_checked
  elsif /deductions$/.match(current_path)
    expect(find("#has_deductions_true")).to be_checked
    expect(find(:css, "#deduction_kind[value='moving_expenses']")).to be_checked
  elsif /benefits$/.match(current_path)
    expect(find("#has_enrolled_health_coverage_false")).to be_checked
    expect(find("#has_eligible_health_coverage_false")).to be_checked
  else 
    expect(find("#is_pregnant_no")).to be_checked
    expect(find("#is_post_partum_period_no")).to be_checked
    expect(find("#is_self_attested_blind_no")).to be_checked
    expect(find("#has_daily_living_no")).to be_checked
    expect(find("#need_help_paying_bills_no")).to be_checked
    expect(find("#radio_physically_disabled_no")).to be_checked
  end
end

Then(/^the "Review Application" link will be disabled$/) do
  find_link('Review Application')['disabled'].should == 'disabled'
end

Then(/^the “Review Application” link will be actionable$/) do
  find_link('Review Application').visible?
end

When(/^clicks the “Review Application” link$/) do
  click_link('Review Application')
end

Then(/^the user will navigate to the Review Application page$/) do
  expect(page).to have_content('Review Your Application')
end

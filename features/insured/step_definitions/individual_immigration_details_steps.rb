Then(/Individual fills demographic details/) do
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find('label[for=radio_incarcerated_no]', wait: 20).click
  choose 'radio_incarcerated_no', visible: false, allow_label_click: true
  fill_in "person_addresses_attributes_0_address_1", :with => "4900 USA BLVD NE"
  fill_in "person_addresses_attributes_0_address_2", :with => "212"
  fill_in "person_addresses_attributes_0_city", :with=> "Washington"
  find(:xpath, "//span[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'DC')]").click
  fill_in "person[addresses_attributes][0][zip]", :with => "20002"
  # screenshot("personal_form")
end

Then(/(.*) selects i327 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-327 – Reentry permit", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'I-327 Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
end


Then("Individual should see the i327 document text") do
  expect(page).to have_content("Enter 9 numbers. Do not enter the ‘A’, or any other characters, letters, or spaces.")
  expect(page).to have_content("If you have an 8-digit alien number, add one zero (0) to the beginning of it")
  expect(page).to have_content("If you have a 7-digit alien number, add two zeros (00) to the beginning of it.")
end

Then(/(.*) selects i551 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-551 – Permanent resident card", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'Card Number', with: (correct_or_incorrect == 'correctly' ? 'AAA0000000000' : '23#AAA0000000000')
  fill_in 'I-551 Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
end


Then("Individual should see the i551 document text") do
  step "Individual should see the i327 document text"
  expect(page).to have_content("The card number is 13 letters and numbers. Enter 3 letters followed by 10 numbers.")
  expect(page).to have_content("Do not enter any other characters or spaces.")
end

Then(/(.*) selects i571 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-571 – Refugee travel document", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'I-571 Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
end

Then("Individual should see the i571 document text") do
  step "Individual should see the i327 document text"
end

Then(/(.*) selects i766 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-766 – Employment authorization card", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'Card Number', with: (correct_or_incorrect == 'correctly' ? 'AAA0000000000' : '23#AAA0000000000')
  fill_in 'I-766 Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
end

Then("Individual should see the i766 document text") do
  step "Individual should see the i551 document text"
end

Then(/(.*) selects Certificate of Citizenship document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Certificate of citizenship", match: :prefer_exact, wait: 10).click
  fill_in 'Certificate Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
end

Then("Individual should see the Certificate of Citizenship document text") do
  expect(page).to have_content("The citizenship number has 6-12 numbers and letters. Do not enter any other characters or spaces.")
  expect(page).to have_content("This number is usually in the upper-right hand corner of the naturalization certificate.")
  expect(page).to have_content("It’s printed in red on all naturalization certificates issued since September 27, 1906.")
end

Then(/(.*) selects Naturalization Certificate document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Naturalization certificate", match: :prefer_exact, wait: 10).click
  fill_in 'Naturalization Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
end

Then("Individual should see the Naturalization Certificate document text") do
  expect(page).to have_content("The naturalization number has 6-12 numbers and letters. Do not enter any other characters or spaces.")
  expect(page).to have_content("This number is usually in the upper-right hand corner of the naturalization certificate.")
  expect(page).to have_content("It’s printed in red on all naturalization certificates issued since September 27, 1906.")
end

Then(/(.*) selects Machine Readable Immigrant Visa document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Machine-readable immigrant visa (with temporary I-551 language)", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'Passport Number', with: (correct_or_incorrect == 'correctly' ? 'L28282483' : '@23#5678901')
end

Then("Individual should see the Machine Readable Immigrant Visa document text") do
  step "Individual should see the Unexpired Foreign Passport document text"
  step "Individual should see the i327 document text"
end

Then(/(.*) selects Temporary i551 Stamp document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Temporary I-551 stamp (on passport or I-94)", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
end

Then("Individual should see the Temporary i551 Stamp document text") do
  step "Individual should see the i327 document text"
end

Then(/(.*) selects i94 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-94 – Arrival/departure record", match: :prefer_exact, wait: 10).click
  fill_in 'I 94 Number', with: (correct_or_incorrect == 'correctly' ? '123456789a1' : '@23#5678901')
end

Then("Individual should see the i94 document text") do
  step 'Individual should see the i94 text'
end

Then(/(.*) selects i94 in Unexpired Foreign Passport document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-94 – Arrival/departure record in unexpired foreign passport", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'I 94 Number', with: (correct_or_incorrect == 'correctly' ? '123456789a1' : '@23#5678901')
  fill_in 'Passport Number', with: (correct_or_incorrect == 'correctly' ? 'L282824' : '@23#5678901')
  fill_in 'Passport Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
end

Then("Individual should see the i94 in Unexpired Foreign Passport document text") do
  step "Individual should see the i94 document text"
  step "Individual should see the Unexpired Foreign Passport document text"
end

Then(/(.*) selects Unexpired Foreign Passport document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Unexpired foreign passport", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'Passport Number', with: (correct_or_incorrect == 'correctly' ? 'L282824' : '@23#5678901')
  fill_in 'Passport Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
end

Then("Individual should see the Unexpired Foreign Passport document text") do
  expect(page).to have_content("When entering a Passport Number, include all numbers and letters. Do not enter any other characters or spaces.")
  expect(page).to have_content("The Passport Number that you enter must have between 6 and 12 numbers and letters.")
end

Then(/(.*) selects i20 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-20 – Certificate of eligibility for nonimmigrant student (F-1) status", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'SEVIS ID', with: (correct_or_incorrect == 'correctly' ? '1234567891' : '@23#5678901')
end

Then("Individual should see the i20 document text") do
  expect(page).to have_content("When entering a SEVIS ID, only include the numbers. Do not enter the 'N' or any other characters or letters. For example: If your SEVIS ID is 'N1234567891' then please enter '1234567891'")
  expect(page).to have_content("The SEVIS ID entered must have 10 digits.")
end

Then(/(.*) selects DS2019 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "DS-2019 Certificate of eligibility for exchange visitor (J-1) status", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'SEVIS ID', with: (correct_or_incorrect == 'correctly' ? '1234567891' : '@23#5678901')
end

Then("Individual should see the DS2019 document text") do
  step "Individual should see the i20 document text"
end

Then(/(.*) selects Other With Alien Number document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Other (with alien number)", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'Document Description', with: (correct_or_incorrect == 'correctly' ? 'alien number document@123' : 'the length of Description should not execeed 35')
end

Then("Individual should see the Other With Alien Number document text") do
  step "Individual should see the i327 document text"
  expect(page).to have_content("Enter the type of document, using no more than 35 characters.")
end

Then(/(.*) selects Other With i94 Number document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Other (with I-94 number)", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'I 94 Number', with: (correct_or_incorrect == 'correctly' ? '123456789a1' : '@23#5678901')
  fill_in 'Document Description', with: (correct_or_incorrect == 'correctly' ? 'i-94 #document information' : 'the length of Description should not execeed 35')
end

Then("Individual should see the Other With i94 Number document text") do
  step "Individual should see the i94 document text"
  expect(page).to have_content("Enter the type of document, using no more than 35 characters.")
end
Then(/Individual fills demographic details/) do
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find('label[for=radio_incarcerated_no]', wait: 20).click
  choose 'radio_incarcerated_no', visible: false, allow_label_click: true
  fill_in "person_addresses_attributes_0_address_1", :with => "4900 USA BLVD"
  fill_in "person_addresses_attributes_0_address_2", :with => "212"
  fill_in "person_addresses_attributes_0_city", :with=> "Washington"
  find(:xpath, "//span[@class='label'][contains(., 'SELECT STATE')]").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'DC')]").click
  fill_in "person[addresses_attributes][0][zip]", :with => "20002"
  screenshot("personal_form")
end

Then(/(.*) selects i327 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-327 (Reentry Permit)", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'I-327 Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
end


Then("Individual should see the i327 document text") do
  expect(page).to have_content("When entering an Alien Number, only include the numbers. Do not enter the 'A' or any other characters or letters. For example: If your Alien Number is 'A123456789' then please enter '123456789'")
  expect(page).to have_content("You must enter exactly 9 digits into the Alien Number field. For Alien Numbers with fewer than 9 digits, add one zero (0) to the beginning of an 8-digit Alien Number and two zeroes (00) to the beginning of a 7-digit Alien Number. For example: If your Alien Number is 'A1234567' then please enter '001234567'.")
  expect(page).to have_content("Pre-1956 certificates do not contain an Alien Number. In this case, enter '999999999' for the Alien Number. (check for 9 digit numbers)")
end

Then(/(.*) selects i551 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-551 (Permanent Resident Card)", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'Card Number', with: (correct_or_incorrect == 'correctly' ? 'AAA0000000000' : '23#AAA0000000000')
  fill_in 'I-551 Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
end


Then("Individual should see the i551 document text") do
  step "Individual should see the i327 document text"
  expect(page).to have_content("Please enter the Card Number. The Card Number is exactly 13 letters and numbers. You must enter three letters followed by 10 numbers. You may not enter any special characters.")
  expect(page).to have_content("How to find the Card Number: The document number, also called a Card Number, is printed on the back of the current version of the card. Previous versions of the card featured the document number and expiration date on the front of the card.")
end

Then(/(.*) selects i571 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-571 (Refugee Travel Document)", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'I-571 Expiration Date', with: TimeKeeper.date_of_record.to_s
  click_link((TimeKeeper.date_of_record + 10.days).day.to_s)
end

Then("Individual should see the i571 document text") do
  step "Individual should see the i327 document text"
end

Then(/(.*) selects i766 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-766 (Employment Authorization Card)", match: :prefer_exact, wait: 10).click
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
  find('li', :text => "Certificate of Citizenship", match: :prefer_exact, wait: 10).click
  fill_in 'Citizenship Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
end

Then("Individual should see the Certificate of Citizenship document text") do
  expect(page).to have_content("When entering a Citizenship Certification Number, include all numbers and letters. Do not enter any other characters or spaces.")
  expect(page).to have_content("The Certification number entered must have between 6 and 12 characters.")
  expect(page).to have_content("How to find Citizenship Certification Number: The Certificate of Citizenship certification number is most often in the upper right hand corner of the Certificate. The Certificate of Citizenship certification number is printed in red on all US Certificates of Citizenship issued since September 27, 1906.")
end

Then(/(.*) selects Naturalization Certificate document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Naturalization Certificate", match: :prefer_exact, wait: 10).click
  fill_in 'Naturalization Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
end

Then("Individual should see the Naturalization Certificate document text") do
  expect(page).to have_content("When entering a Naturalization Number, include all numbers and letters. Do not enter any other characters or spaces.")
  expect(page).to have_content("The Naturalization Number entered must have between 6 and 12 numbers and letters. How to find the Naturalization Number: The Naturalization Certificate Number is most often in the upper right hand corner of the Certificate. The Naturalization Certificate Number is printed in red on all US Certificates of Citizenship issued since September 27, 1906.")
end

Then(/(.*) selects Machine Readable Immigrant Visa document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Machine Readable Immigrant Visa (with Temporary I-551 Language)", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'Passport Number', with: (correct_or_incorrect == 'correctly' ? 'L28282483' : '@23#5678901')
end

Then("Individual should see the Machine Readable Immigrant Visa document text") do
  step "Individual should see the Unexpired Foreign Passport document text"
  step "Individual should see the i327 document text"
end

Then(/(.*) selects Temporary i551 Stamp document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Temporary I-551 Stamp (on passport or I-94)", match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
end

Then("Individual should see the Temporary i551 Stamp document text") do
  step "Individual should see the i327 document text"
end

Then(/(.*) selects i94 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-94 (Arrival/Departure Record)", match: :prefer_exact, wait: 10).click
  fill_in 'I 94 Number', with: (correct_or_incorrect == 'correctly' ? '123456789a1' : '@23#5678901')
end

Then("Individual should see the i94 document text") do
  step 'Individual should see the i94 text'
end

Then(/(.*) selects i94 in Unexpired Foreign Passport document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "I-94 (Arrival/Departure Record) in Unexpired Foreign Passport", exact_text: true, match: :prefer_exact, wait: 10).click
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
  find('li', :text => "Unexpired Foreign Passport", exact_text: true, match: :prefer_exact, wait: 10).click
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
  find('li', :text => "I-20 (Certificate of Eligibility for Nonimmigrant (F-1) Student Status)", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'SEVIS ID', with: (correct_or_incorrect == 'correctly' ? '1234567891' : '@23#5678901')
end

Then("Individual should see the i20 document text") do
  expect(page).to have_content("When entering a SEVIS ID, only include the numbers. Do not enter the 'N' or any other characters or letters. For example: If your SEVIS ID is 'N1234567891' then please enter '1234567891'")
  expect(page).to have_content("The SEVIS ID entered must have 10 digits.")
end

Then(/(.*) selects DS2019 document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "DS2019 (Certificate of Eligibility for Exchange Visitor (J-1) Status)", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'SEVIS ID', with: (correct_or_incorrect == 'correctly' ? '1234567891' : '@23#5678901')
end

Then("Individual should see the DS2019 document text") do
  step "Individual should see the i20 document text"
end

Then(/(.*) selects Other With Alien Number document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Other (With Alien Number)", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'Alien Number', with: (correct_or_incorrect == 'correctly' ? '123456789' : '@23#5678901')
  fill_in 'Document Description', with: (correct_or_incorrect == 'correctly' ? 'alien number document 123' : '@23#5678901')
end

Then("Individual should see the Other With Alien Number document text") do
  step "Individual should see the i327 document text"
end

Then(/(.*) selects Other With i94 Number document and fills required details (.*)$/) do |text, correct_or_incorrect|
  find('.label', :text => 'Select document type', wait: 20).click
  find('li', :text => "Other (With I-94 Number)", exact_text: true, match: :prefer_exact, wait: 10).click
  fill_in 'I 94 Number', with: (correct_or_incorrect == 'correctly' ? '123456789a1' : '@23#5678901')
  fill_in 'Document Description', with: (correct_or_incorrect == 'correctly' ? 'i 94 document information' : '@23#5678901')
end

Then("Individual should see the Other With i94 Number document text") do
  step "Individual should see the i94 document text"
end
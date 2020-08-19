Given(/^that the consumer has navigated to the AUTH & CONSENT page$/) do
	visit 'insured/consumer_role/ridp_agreement'
end

When(/^the consumer selects “I Disagree”$/) do
		find(:xpath, '//label[@for="agreement_disagree"]').click
end

When(/^the consumer clicks CONTINUE$/) do
	click_link "Continue"
end

Then(/^the consumer will be directed to the DOCUMENT UPLOAD page$/) do
	expect(page).to have_content('Identity')
	expect(page).to have_content('Application')
end

Given(/^that the consumer has “Disagreed” to AUTH & CONSENT$/) do
	visit 'insured/consumer_role/ridp_agreement'
	find(:xpath, '//label[@for="agreement_disagree"]').click
	click_link "Continue"
end

And(/^the consumer is on the DOCUMENT UPLOAD page$/) do
	expect(page).to have_content('Identity')
	expect(page).to have_content('Application')
end

And(/^application verification is OUTSTANDING$/) do
	person = Person.all.first
  expect(person.consumer_role.application_validation).to eq('outstanding')
  expect(page).to have_content('Outstanding')
end

And(/^Identity verification is OUTSTANDING$/) do
	person = Person.all.first
	expect(person.consumer_role.identity_validation).to eq('outstanding')
	expect(page).to have_content('Outstanding')
end

Then(/^the CONTINUE button is functionally DISABLED$/) do
	find('.interaction-click-control-continue')['disabled'].should == "disabled"
end

Then(/^visibly DISABLED$/) do
	find('.interaction-click-control-continue')['disabled'].should == "disabled"
end

And(/^an uploaded application in REVIEW status is present$/) do
  doc_id  = "urn:openhbx:terms:v1:file_storage:s3:bucket:'id-verification'{#sample-key}"
  file_path = File.dirname(__FILE__)
  allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_path).and_return(file_path)
  allow(Aws::S3Storage).to receive(:save).with(file_path, 'id-verification').and_return(doc_id)
  find('#upload_application').click
	within '#upload_application' do
		attach_file("file[]", "#{Rails.root}/lib/pdf_templates/blank.pdf", visible:false)
  end
  wait_for_ajax(2)
	expect(page).to have_content('File Saved')
	expect(page).to have_content('In Review')
	person = Person.all.first
	expect(person.consumer_role.application_validation).to eq('pending')
end

And(/^an uploaded identity verification in REVIEW status is present$/) do
  doc_id  = "urn:openhbx:terms:v1:file_storage:s3:bucket:'id-verification'{#sample-key}"
  file_path = File.dirname(__FILE__)
  allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_path).and_return(file_path)
  allow(Aws::S3Storage).to receive(:save).with(file_path, 'id-verification').and_return(doc_id)
	find('#upload_identity').click
	find('#select_upload_identity').click
	within '#select_upload_identity' do
		attach_file("file[]", "#{Rails.root}/lib/pdf_templates/blank.pdf", visible:false)
  end
  wait_for_ajax(2)
	expect(page).to have_content('File Saved')
	expect(page).to have_content('In Review')
	person = Person.all.first
	expect(person.consumer_role.identity_validation).to eq('pending')
end

And(/^an uploaded application in VERIFIED status is present$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., 'Families')]", :wait => 10).click
  find(:xpath,'//*[@id="myTab"]/li[2]/ul/li[1]/a/span[1]', :wait => 10).trigger('click')
  wait_for_ajax(10,2)
  family_member = find('a', :text => /First/)
  family_member.trigger("click")
  expect(page).to have_content('Application')
  find(:xpath, "/html/body/div[2]/div[2]/div/div/div[1]/div[2]/div/div/div/div[2]/div[5]/div/div[4]/div").click
  find('.interaction-choice-control-verification-reason-1').click
  find(:xpath, '//*[@id="verification_reason"]').trigger('click')
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click
  expect(page).to have_content('Application successfully verified.')
end

And(/^an uploaded Identity verification in VERIFIED status is present$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., '#{"Families"}')]", :wait => 10).click
  find(:xpath,'//*[@id="myTab"]/li[2]/ul/li[1]/a/span[1]', :wait => 10).trigger('click')
  wait_for_ajax(10,2)
  family_member = find('a', :text => /First/)
  family_member.trigger("click")
  expect(page).to have_content('Identity')
  find(:xpath, "/html/body/div[2]/div[2]/div/div/div[1]/div[2]/div/div/div/div[2]/div[1]/div/div[4]/div").click
  find('.interaction-choice-control-verification-reason-1').click
  find(:xpath, '//*[@id="verification_reason"]').trigger('click')
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click
  expect(page).to have_content('Identity successfully verified.')
end

Then(/^the CONTINUE button is functionally ENABLED$/) do
  find('.interaction-click-control-continue').visible?
end

Then(/^visibly ENABLED$/) do
  find('.interaction-click-control-continue').visible?
end

When(/^the Admin clicks “Continue” on the doc upload page$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., '#{"Families"}')]", :wait => 10).click
  find(:xpath,'//*[@id="myTab"]/li[2]/ul/li[1]/a/span[1]', :wait => 10).trigger('click')
  wait_for_ajax(10,2)
  family_member = find('a', :text => /First/)
  family_member.trigger("click")
end

Then(/^the Admin is unable to complete the application for the consumer until ID is verified$/) do
  find('.interaction-click-control-continue')['disabled'].should == "disabled"
end


When(/^the consumer selects “I Agree”$/) do
  expect(page).to have_content('Authorization and Consent')
  find(:xpath, '//label[@for="agreement_agree"]').click
  click_link "Continue"
end

Then(/^the consumer will be directed to answer the Experian Identity Proofing questions$/) do
  expect(page).to have_content('Verify Identity')
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]').click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]').click
end

And(/^that the consumer has answered the Experian Identity Proofing questions$/) do
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]').click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]').click
  screenshot("identify_verification")
  click_button "Submit"
end

When(/^Experian is unable to verify Identity for the consumer$/) do
  expect(page).to have_content('Identity')
  expect(page).to have_content('Application')
end

When(/^an Experian Error screen appears for the consumer$/) do
  expect(page).to have_content('Your identity could not be confirmed by Experian')
end

When(/^an uploaded Identity verification in VERIFIED status is present on failed experian screen$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., '#{"Families"}')]", :wait => 10).click
  find(:xpath,'//*[@id="myTab"]/li[2]/ul/li[1]/a/span[1]', :wait => 10).trigger('click')
  wait_for_ajax(10,2)
  family_member = find('a', :text => /First/)
  family_member.trigger("click")
  expect(page).to have_content('Identity')
  find(:xpath, "/html/body/div[2]/div[2]/div/div/div[1]/div[3]/div[1]/div/div/div/div[2]/div[1]/div/div[4]/div").click
  find('.interaction-choice-control-verification-reason-1').click
  find(:xpath, '//*[@id="verification_reason"]').trigger('click')
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click
  expect(page).to have_content('Identity successfully verified.')
end

When(/^an uploaded application in VERIFIED status is present on failed experian screen$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., '#{"Families"}')]", :wait => 10).click
  find(:xpath,'//*[@id="myTab"]/li[2]/ul/li[1]/a/span[1]', :wait => 10).trigger('click')
  wait_for_ajax(10,2)
  family_member = find('a', :text => /First/)
  family_member.trigger("click")
  expect(page).to have_content('Application')
  find(:xpath, "/html/body/div[2]/div[2]/div/div/div[1]/div[3]/div[1]/div/div/div/div[2]/div[5]/div/div[4]/div").click
  find('.interaction-choice-control-verification-reason-1').click
  find(:xpath, '//*[@id="verification_reason"]').trigger('click')
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click
  expect(page).to have_content('Application successfully verified.')
end

Then(/^HBX admin should see the dependents form$/) do
  expect(page).to have_content('Add Member')
  screenshot("dependents")
end

And(/^HBX admin answers "No" on help paying for coverage page and clicks continue$/) do
  find(:xpath, '//*[@id="help_paying_coverage"]/div/div[3]/label').click
  find(:xpath, "//*[@id='btn-continue']").click
end

And(/^HBX admin click on continue button on household info form$/) do
  find(:xpath, "//*[@id='btn-continue']").click
end

And(/^HBX admin clicks continue after approving Identity document$/) do
  find(:xpath, "//*[@id='btn-continue']").click
end

When(/^HBX admin click on none of the situations listed above apply checkbox$/) do
  expect(page).to have_content 'None of the situations listed above apply'
  find(:xpath, '//*[@id="no_qle_checkbox"]').trigger('click')
  expect(page).to have_content 'To enroll before open enrollment'
end

And(/^HBX admin click on back to my account button$/) do
  expect(page).to have_content "To enroll before open enrollment, you must qualify for a special enrollment period"
  find('.interaction-click-control-back-to-my-account').click
end

Then(/^HBX admin should land on home page$/) do
  expect(page).to have_content 'My DC Health Link'
end

And(/^I click on Continue button$/) do
  find(:xpath, "//*[@id='btn-continue']").click
end

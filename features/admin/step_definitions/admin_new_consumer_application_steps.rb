Given(/^Hbx Admin is on ridp document upload page$/) do
  visit '/insured/consumer_role/upload_ridp_document'
end

When(/^hbx admin uploads application document and verifies application$/) do
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
  find(:xpath, "/html/body/div[2]/div[3]/div/div/div[1]/div[2]/div/div/div/div[2]/div[5]/div/div[4]/div/div[2]").click
  find('.interaction-choice-control-verification-reason-1').click
  find(:xpath, '//*[@id="verification_reason"]').trigger('click')
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click

  expect(page).to have_content('Application successfully verified.')
end

Then(/^Hbx admin visits household info page$/) do
  expect(page).to have_content('Household Info')
end

Then(/^Admin continues to families home page$/) do
  visit 'families/home'
end

When(/^user registers as an individual$/) do
  fill_in "person_first_name", with: "John"
  fill_in "person_last_name", with: "Smith"
  fill_in "jq_datepicker_ignore_person_dob", with: "11/11/1991"
  fill_in "person_ssn", with: '212-31-3131'
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  screenshot("register")
  find('.btn', text: 'CONTINUE').click
end

When(/^the Individual selects “I Disagree”$/) do
  find(:xpath, '//label[@for="agreement_disagree"]').click
end

When(/^the Individual clicks CONTINUE$/) do
  click_link "Continue"
end

Then(/^Individual should land on Documents upload page$/) do
  expect(page).to have_content('Verified')
  expect(page).to have_content('Identity')
  expect(page).to have_content('Application')
end

When(/^clicks on Individual in Families tab$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., '#{"Families"}')]", :wait => 10).click
  find(:xpath,'//*[@id="myTab"]/li[2]/ul/li[1]/a/span[1]', :wait => 10).trigger('click')
  wait_for_ajax(10,2)
  family_member = find('a', :text => /\AJohn Smith\z/)
  family_member.trigger("click")
  expect(page).to have_content('Identity')
end

Then(/^Admin should land on ridp document upload page$/) do
  expect(page).to have_content('Identity')
end


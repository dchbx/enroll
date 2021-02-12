When(/^the Admin selects the In Person application option$/) do
  find('li', :text => 'In Person').click
end

When(/^the Admin clicks CONTINUE after uploading and verifying an Identity$/) do
  find('#upload_identity').click
  find('#select_upload_identity')
  within '#select_upload_identity' do
    attach_file('file[]', "#{Rails.root}/lib/pdf_templates/blank.pdf", visible: false)
  end
  wait_for_ajax(10, 2)
  within('#Identity') do
    find('.label', :text => "Action").click
    find('li', :text => 'Verify').click
  end
  wait_for_ajax(10, 2)
  find('.verification-update-reason').click
  find('li', :text => 'Document in EnrollApp').click
  find('.v-type-confirm-button').click
  expect(page).to have_content('Identity successfully verified.')
  find('.button', text: 'CONTINUE').click
end

Then(/^the Admin should be on the Help Paying for Coverage page$/) do
  expect(page).to have_content IvlFaaHelpPayingForCoverage.help_paying_coverage_text
end

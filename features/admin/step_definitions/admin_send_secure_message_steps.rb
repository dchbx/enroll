Then(/^the user will( not)? see the Send Secure Message button$/) do |visible|
  if visible.blank?
    if ::EnrollRegistry.feature_enabled?(:send_secure_message_employer) == true
      expect(page).to have_css('.btn.btn-xs', text: 'Send Secure Message')
    else
      expect(page).to_not have_css('.btn.btn-xs', text: 'Send Secure Message')
    end
  else
    expect(page).to_not have_css('.btn.btn-xs', text: 'Send Secure Message')
  end
end

When(/^the user clicks the Send Secure Message button for this Employer$/) do
  find('.btn.btn-xs', text: 'Send Secure Message').click
end

Then(/^the Secure message form should have Subject and Content as required fields$/) do
  find_field('subject')[:required].should be_present
  find_field('body')[:required].should be_present
end

Then(/^Admin enters form with subject and content and click send$/) do
  fill_in 'subject', :with => 'Send Secure Subject.'
  fill_in 'body', :with => 'Send secure message regarding.'
  page.find('#send_secure_message').click
end

Then(/^Should( not)? see a dialog box for confirmation$/) do |visible|
  if visible.blank?
    page.find('#sendSecure')
  else
    expect(page).to_not have_text('Are you sure?')
  end
end

Then(/^Should click on confirm button$/) do
  find('.btn.btn-primary', text: 'CONFIRM').click
end

Then(/^Should click on cancel button$/) do
  find('.btn.btn-default.pull-left', text: 'Cancel').click
end

Then(/^Should see success message$/) do
  expect(page).to have_text('Message sent successfully')
end

Then(/^the user will see the Send Secure Message option form$/) do
  expect(page).to have_css('input[type="file"]')
  expect(page).to have_text('RECIPIENT')
  expect(page).to have_text('SUBJECT')
  expect(page).to have_text('CONTENT')
  expect(page).to have_text('DOCUMENT')
  expect(page).to have_css("textarea[placeholder='Write here...']")
  expect(page).to have_button('Send', disabled: false)
  expect(page).to have_button('Cancel', disabled: false)
end

Then(/^the user will not see the Send Secure Message option form$/) do
  expect(page).not_to have_css('input[type="file"]')
  expect(page).not_to have_text('RECIPIENT')
  expect(page).not_to have_text('SUBJECT')
  expect(page).not_to have_text('CONTENT')
  expect(page).not_to have_text('DOCUMENT')
  expect(page).not_to have_css("textarea[placeholder='Write here...']")
  expect(page).not_to have_button('Send', disabled: false)
  expect(page).not_to have_button('Cancel', disabled: false)
end

When(/^the user clicks cancel button$/) do
  find("#secureMessageFormClose").click
end

Then(/^the Recipient field should auto populate with the Employer groups name (.*?)$/) do|legal_name|
  expect(page).to have_text(legal_name)
end
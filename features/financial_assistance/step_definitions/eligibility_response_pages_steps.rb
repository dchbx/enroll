Given(/^the application is correct$/) do
  FinancialAssistance::Application.any_instance.should_receive(:publish).and_return(true)
  FinancialAssistance::Application.all.where(:'id'.in => [@application.id]).first.delete
  application = FinancialAssistance::Application.all[0]
  application.family.active_household.tax_households << TaxHousehold.new(effective_ending_on: nil, effective_starting_on: TimeKeeper.date_of_record, is_eligibility_determined: false, application_id: @application.id)
  application.active_applicants.first.tax_household = application.family.active_household.tax_households.first
end

Given(/^the user qualifies for "([^"]*)"$/) do |type|
  application = FinancialAssistance::Application.all[0]
  application.update_attributes!(aasm_state: 'determined', assistance_year: 2018, determination_http_status_code: 200)
  application.tax_households.each do |txh|
    txh.update_attributes!(allocated_aptc: 200.00, is_eligibility_determined: true, effective_starting_on: Date.new(2018, 01, 01))

    new_eligible = EligibilityDetermination.new( max_aptc: 200.00, csr_percent_as_integer: 73,
                                                 csr_eligibility_kind: 'csr_73',
                                                 determined_on: TimeKeeper.datetime_of_record - 30.days,
                                                 determined_at: TimeKeeper.datetime_of_record - 30.days,
                                                 premium_credit_strategy_kind: 'allocated_lump_sum_credit',
                                                 e_pdc_id: '3110344',
                                                 source: 'Haven'
    )
    txh.eligibility_determinations << new_eligible

    case type
    when 'medicaid'
      txh.applicants.first.update_attributes!(is_medicaid_chip_eligible: true, is_ia_eligible: false, is_without_assistance: false)
    when 'assistance'
      txh.applicants.first.update_attributes!(is_medicaid_chip_eligible: false, is_ia_eligible: true, is_without_assistance: false)
    else
      txh.applicants.first.update_attributes!(is_medicaid_chip_eligible: false, is_ia_eligible: false, is_without_assistance: true)
    end
    application.applicants.each do |applicant|
      applicant.update_attributes!(:assisted_income_validation => 'outstanding', :assisted_mec_validation => 'outstanding', aasm_state: 'verification_outstanding')
      applicant.verification_types.each {|verification| verification.update_attributes!(validation_status: 'outstanding')}
    end
  end
  th = application.tax_households
  FinancialAssistance::Application.any_instance.stub(:tax_households).and_return(th)
end

Then(/^the user is on the Eligibility Results page$/) do
  sleep(20)
  expect(page).to have_content 'Eligibility Results'
  expect(page).to have_content 'We have your results!'
end

Then(/^the user is on the Eligibility Response Error page$/) do
  sleep(20)
  expect(page).to have_content 'Eligibility Response Error'
end

Given(/^the user is on the Waiting for Results page$/) do
  expect(page).to have_content 'Waiting for your eligibility results...'
end

Then(/^the user's "([^"]*)" results show$/) do |type|
  case type
  when 'medicaid'
    expect(page).to have_content("These people appear to be eligible for Medicaid:\n#{application.applicants.first.person.first_name} #{application.applicants.first.person.last_name}")
  when 'no assistance'
    expect(page).to have_content("These people qualify to enroll in a private health insurance plan:\n#{application.applicants.first.person.first_name} #{application.applicants.first.person.last_name}")
  else
    expect(page).to have_content(/These people are eligible for savings of (\d+.\d+) per month called an advance premium tax credit./)
    expect(page).to have_content("This means they won't have to pay full price for health insurance.\n#{application.applicants.first.person.first_name} #{application.applicants.first.person.last_name}")
  end
end

When(/^the user clicks View My Applications$/) do
  find('span', text: 'View My Applications').click
end

Then(/^the user will be on the Cost Savings Applications page$/) do
  expect(page).to have_content('Cost Savings Applications')
end
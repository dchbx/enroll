# frozen_string_literal: true

Given(/^the Reinstate feature configuration is enabled$/) do
  enable_feature :benefit_application_reinstate
end

Given(/^the Reinstate feature configuration is disabled$/) do
  disable_feature :benefit_application_reinstate
end

Then(/^the user will (.*) Reinstate button$/) do |action|
  action == 'see' ? (page.has_css?('Reinstate') == true) : (page.has_css?('Reinstate') == false)
end

When("Admin clicks on Reinstate button") do
  find('li', :text => 'Reinstate').click
end

Then("Admin will see transmit to carrier checkbox") do
  expect(page).to have_content('Transmit to Carrier')
end

Then(/^Admin will see Reinstate Start Date for (.*) benefit application$/) do |aasm_state|
  ben_app = ::BenefitSponsors::Organizations::Organization.find_by(legal_name: /ABC Widgets/).active_benefit_sponsorship.benefit_applications.first
  expect(page.all('tr').detect { |tr| tr[:id] == ben_app.id.to_s }.present?).to eq true
  if ['terminated','termination_pending'].include?(aasm_state)
    value = page.all('input').detect { |input| input[:reinstate_start_date] == ben_app.end_on.next_day.to_date.to_s}
    expect(value.present?).to eq true
  else
    expect(page).to have_content(ben_app.start_on.to_date.to_s)
  end
end

When("Admin clicks on Submit button") do
  find('.plan-year-submit').click
end

Then("Admin will see confirmation pop modal") do
  expect(page).to have_content('Would you like to reinstate the plan year?')
end

When("Admin clicks on continue button for reinstating benefit_application") do
  click_button 'Continue'
  sleep 1
end

Then("Admin will see a Successful message") do
  sleep 2
  expect(page).to have_content(/Plan Year Reinstated Successfully/)
end

And(/^initial employer ABC Widgets has updated (.*) effective period for reinstate$/) do |aasm_state|
  if aasm_state == 'canceled'
    employer_profile.benefit_applications.first.workflow_state_transitions << WorkflowStateTransition.new(from_state: 'active', to_state: 'canceled', event: 'cancel!')
    cancel_ba = employer_profile.benefit_applications.first
    start_on = cancel_ba.benefit_sponsor_catalog.effective_period.min.prev_year
    end_on = cancel_ba.benefit_sponsor_catalog.effective_period.max.prev_year
    effective_period = start_on..end_on
    cancel_ba.benefit_sponsor_catalog.update_attributes!(effective_period: effective_period)
    employer_profile.benefit_applications.first.update_attributes!(effective_period: effective_period)
  end
end

And(/^initial employer ABC Widgets application (.*)$/) do |aasm_state|
  application = employer_profile.benefit_applications.first
  if aasm_state == 'termination_pending'
    updated_dates = application.effective_period.min.to_date..TimeKeeper.date_of_record.last_month.end_of_month
    application.update_attributes!(:effective_period => updated_dates, :terminated_on => TimeKeeper.date_of_record, termination_reason: 'nonpayment')
    application.schedule_enrollment_termination!
  elsif  aasm_state == 'terminated'
    updated_dates = application.effective_period.min.to_date..TimeKeeper.date_of_record.prev_month.end_of_month
    application.update_attributes!(:effective_period => updated_dates, :terminated_on => TimeKeeper.date_of_record, termination_reason: 'nonpayment')
    application.terminate_enrollment!
  elsif ['retroactive_canceled', 'canceled'].include?(aasm_state)
    if aasm_state == 'retroactive_canceled'
      application.cancel!
    else
      application.update_attributes(aasm_state: :canceled)
      application.workflow_state_transitions << WorkflowStateTransition.new(from_state: 'active', to_state: 'canceled', event: 'cancel!')
      application.benefit_packages.each(&:cancel_member_benefits)
    end
  end
end

Given("terminated benefit application effective_period updated") do
  @terminated_ba = employer_profile.benefit_applications.first
  start_on = @terminated_ba.effective_period.min
  end_on = TimeKeeper.date_of_record.beginning_of_month - 1.day
  effective_period = start_on..end_on
  @terminated_ba.update_attributes!(effective_period: effective_period)
end

Given("active benefit application is a reinstated benefit application") do
  reinstated_ba = employer_profile.benefit_applications.where(aasm_state: :active).first
  start_on_ba = @terminated_ba.effective_period.max + 1.day
  end_on_ba = reinstated_ba.effective_period.max
  effective_period = start_on_ba..end_on_ba
  reinstated_ba.update_attributes!(effective_period: effective_period, reinstated_id: @terminated_ba.id)
end

And(/^(.*) should see a reinstated indicator on benefit application$/) do |_user|
  expect(page).to have_content('Reinstated')
end

When("the Admin click on the employer ABC Widgets") do
  find('.interaction-click-control-abc-widgets').click
end

Then("Admin lands on employer ABC Widgets profile") do
  expect(page).to have_content('ABC Widgets')
end

# frozen_string_literal: true

Then(/^Hbx Admin sees Families link$/) do
  expect(page).to have_text("Families")
end

When(/^Hbx Admin click Families link$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-families').click
  wait_for_ajax
  find(:xpath, "//*[@id='myTab']/li[2]/ul/li[2]/a", :wait => 10).click
  wait_for_ajax
end

When(/^Hbx Admin clicks Actions button$/) do
  find_all('.dropdown.pull-right', text: 'Actions')[0].click
end

When(/^Hbx Admin click Families dropdown/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-families').click
  wait_for_ajax
end

Then(/^Hbx Admin should see an Edit APTC \/ CSR link$/) do
  find_link('Edit APTC / CSR').visible?
end

Given(/^User with tax household exists$/) do
  person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
  @person_name = person.full_name
  person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
  @family = FactoryBot.create(:family, :with_primary_family_member, person: person)
  tax_household = FactoryBot.create(:tax_household, household: @family.active_household, effective_ending_on: nil)
  FactoryBot.create(:eligibility_determination, tax_household: tax_household, max_aptc: Money.new(1000, 'USD'), csr_eligibility_kind: 'csr_100')
  issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
  product = FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile, metal_level_kind: :catastrophic)
  @enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                  :family => @family,
                                  :household => @family.active_household,
                                  :aasm_state => 'coverage_selected',
                                  :is_any_enrollment_member_outstanding => true,
                                  :kind => 'individual',
                                  :product => product,
                                  :effective_on => TimeKeeper.date_of_record.beginning_of_year)
  FactoryBot.create(:hbx_enrollment_member, applicant_id: @family.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: @enrollment)
  @enrollment.save!
end


When(/^Hbx Admin clicks on the Update APTC CSR button$/) do
  find_link('Edit APTC / CSR').click
end


Then(/^Hbx Admin should see cat plan error message$/) do
  wait_for_ajax
  fill_in "aptc_applied_#{@enrollment.id}", with: "23.00"
  find(".toggle_update_btn").click
  wait_for_ajax(3,2)
  expect(page).to have_content(Settings.aptc_errors.cat_plan_error)
end

Given(/^oustanding verfications users exists$/) do
  people = [["Aaron", "Anderson"], ["Zach", "Zackary"]]
  @person_names = []
  people.each do |name_hash|
    person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: name_hash[0], last_name: name_hash[1])
    @person_names << person.full_name
    person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
    family = FactoryBot.create(:family, :with_primary_family_member, person: person)
    issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
    product = FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile)
    enrollment = FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      :family => family,
      :household => family.active_household,
      :aasm_state => 'coverage_selected',
      :is_any_enrollment_member_outstanding => true,
      :kind => 'individual',
      :product => product,
      :effective_on => TimeKeeper.date_of_record.beginning_of_year
    )
    FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment)
    enrollment.save!
    Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.is_any_enrollment_member_outstanding' => true)
  end
end

# Must contain contingent_enrolled_active_family_members
Given(/^user with best verification due date 3 months from now is present$/) do
  @person_names = []
  person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: "Kyle", last_name: "Dore")
  @person_names << person.full_name
  person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
  family_in_range = FactoryBot.create(:family, :with_primary_family_member, person: person)
  issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
  product = FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile)
  enrollment = FactoryBot.create(
    :hbx_enrollment,
    :with_enrollment_members,
    :family => family_in_range,
    :household => family_in_range.active_household,
    :aasm_state => 'coverage_selected',
    :is_any_enrollment_member_outstanding => true,
    :kind => 'individual',
    :product => product,
    :effective_on => TimeKeeper.date_of_record.beginning_of_year
  )
  FactoryBot.create(:hbx_enrollment_member, applicant_id: family_in_range.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment)
  enrollment.save!
  Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.is_any_enrollment_member_outstanding' => true)
  individual_market_transitions = person.individual_market_transitions.create!(role_type: 'consumer', reason_code: 'initial_individual_market_transition_created_using_data_migration')
  expect(person.primary_family.enrollments.verification_needed.where(:"hbx_enrollment_members.applicant_id" => person.primary_family.family_members.last.id).first.present?).to eq(true)
  # TODO: Doesn't work for some reason
  # person.verification_types.last.update_attributes!(validation_status: "outstanding", inactive: false)
  target_verification_type = person.verification_types.last.update_attributes!(validation_status: "outstanding", update_reason: "cucumber")
  person.reload
  expect(person.verification_types.where(validation_status: "outstanding").present?).to eq(true)
  person.verification_types.last.reload
  # TODO: This never persists the validation status into this method
  # expect(person.primary_family.contingent_enrolled_family_members_due_dates.present?).to eq(true)
  expect(person.is_consumer_role_active?).to eq(true)
  expect(family_in_range.best_verification_due_date).to eq(TimeKeeper.date_of_record + 95.days)
  # verification_types = person.verification_types.create!(applied_roles: 'consumer_role')
end

And(/^other users do not have a best verification due date$/) do
  Family.all.each do |family|
    if family.primary_person.first_name != "Kyle" && family.primary_person.last_name != "Dore"
      expect(family.best_verification_due_date.blank?).to eq(true)
    end
  end
end

And(/^Admin searches for user with best verification date between 8 months and 5 months ago$/) do
  fill_in 'custom_datatable_date_from', with: ((TimeKeeper.date_of_record + 95.days) - 1.month).strftime('%Y-%m-%d').to_s
  fill_in 'custom_datatable_date_to', with: (TimeKeeper.date_of_record + 95.days).strftime('%Y-%m-%d').to_s
  find('#date_range_apply').click
  sleep 5
end

Given(/^one fully uploaded person exists$/) do
  name_hash = ["Michael", "Fox"]
  @fully_verified_names = []
  fully_uploaded_person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: name_hash[0], last_name: name_hash[1])
  @fully_verified_names << fully_uploaded_person.full_name
  fully_uploaded_person.consumer_role.update_attributes!(aasm_state: "fully_verified")
  fully_uploaded_family = FactoryBot.create(:family, :with_primary_family_member, person: fully_uploaded_person)
  issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
  product = FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile)
  fully_uploaded_enrollment = FactoryBot.create(
    :hbx_enrollment,
    :with_enrollment_members,
    :family => fully_uploaded_family,
    :household => fully_uploaded_family.active_household,
    :aasm_state => 'coverage_selected',
    :kind => 'individual',
    :product => product,
    :effective_on => TimeKeeper.date_of_record.beginning_of_year
  )
  fully_uploaded_person_enrollment_member = FactoryBot.create(:hbx_enrollment_member, applicant_id: fully_uploaded_family.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: fully_uploaded_enrollment)
  expect(fully_uploaded_enrollment.hbx_enrollment_members).to include(fully_uploaded_person_enrollment_member)
  fully_uploaded_person.consumer_role.update_attributes!(aasm_state: 'verification_outstanding')
  fully_uploaded_enrollment.save!
  expect(fully_uploaded_enrollment.is_any_enrollment_member_outstanding).to eq(true)
  fully_uploaded_family.update_attributes!(vlp_documents_status: "Fully Uploaded")
  expect(Family.vlp_fully_uploaded.last).to eq(fully_uploaded_family)
  expect(Family.where(:_id.in => HbxEnrollment.individual_market.enrolled_and_renewing.by_unverified.distinct(:family_id))).to include(fully_uploaded_family)
  expect(Family.outstanding_verification_datatable.to_a).to include(fully_uploaded_family)
end

When(/^Admin clicks Outstanding Verifications$/) do
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., 'Families')]", :wait => 10).click
  page.find('.interaction-click-control-outstanding-verifications').click
end

When(/^Admin clicks Families tab$/) do
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., 'Families')]", :wait => 10).click
  find('li', :text => 'Families', :class => 'tab-second', :wait => 10).click
end

Then(/^the Admin is navigated to the Families screen$/) do
  expect(page).to have_selector 'h1', text: 'Families'
end

And 'I click on the name of a person of family list' do
  find('a', :text => /First*/i).click
end

Then(/^the Admin is navigated to the Outstanding Verifications screen$/) do
  expect(page).to have_xpath("//div[contains(@class, 'container')]/h1", text: 'Outstanding Verifications')
end


Then(/^the Admin has the ability to use the following filters for documents provided: Fully Uploaded, Partially Uploaded, None Uploaded, All$/) do
  expect(page).to have_xpath('//*[@id="Tab:vlp_partially_uploaded"]', text: 'Partially Uploaded')
  expect(page).to have_xpath('//*[@id="Tab:vlp_fully_uploaded"]', text: 'Fully Uploaded')
  expect(page).to have_xpath('//*[@id="Tab:vlp_none_uploaded"]', text: 'None Uploaded')
  expect(page).to have_xpath('//*[@id="Tab:all"]', text: 'All')
end

And(/^Admin clicks the Fully Uploaded filter and does not see results$/) do
  fully_uploaded = page.all('div').detect { |div| div[:id] == 'Tab:vlp_fully_uploaded' }
  fully_uploaded.click
  # TODO: This stopped working
  sleep 10
  @person_names.each do |person_name|
    expect(page).to_not have_content(person_name)
  end
end

And(/^Admin clicks the Fully Uploaded filter and only sees fully uploaded results$/) do
  expect(Family.vlp_fully_uploaded.count).to eq(1)
  fully_uploaded = page.all('div').detect { |div| div[:id] == 'Tab:vlp_fully_uploaded' }
  fully_uploaded.click
  sleep 10
  # Not fully uploaded
  @person_names.each do |person_name|
    expect(page).to_not have_content(person_name)
  end
  # Fully uploaded
  @fully_verified_names.each do |person_name|
    expect(page).to have_content(person_name)
  end
end

And(/^Admin clicks All and sees all of the results$/) do
  all_people = page.all('div').detect { |div| div[:id] == 'Tab:all' }
  all_people.click
  sleep 5
  @person_names.each do |person_name|
    expect(page).to have_content(person_name)
  end
end

And(/^Admin clicks Documents Uploaded and sorts results by documents uploaded$/) do
  documents_uploaded_sort = page.all('th').detect { |th| th[:class] == 'col-string col-documents_uploaded sorting' }
  documents_uploaded_sort.click
  sleep 5
end


And(/^Admin clicks Name and sorts results by name$/) do
  # Name: activate to sort column descending
  name_sort = page.all('th').detect { |th| th[:class] == 'col-string col-name sorting' }
  name_sort.click
  sleep 5
  # A name will appear here first
  name_sort = page.all('th').detect { |th| th[:class] == 'col-string col-name sorting_asc' }
  name_sort.click
  sleep 5
  # Z name will appear here first
end

Then(/^the Admin is directed to that user's My DC Health Link page$/) do
  # First person name
  click_link @person_names[0]
  expect(page).to have_content("My DC Health Link")
  expect(page).to have_content(@person_names[0])
end


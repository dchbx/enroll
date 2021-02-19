module GeneralAgencyWorld
  def assign_roles_to_general_agency
    general_agency_profile.general_agency_staff_roles << primary_general_agency_staff_role
    general_agency_profile.save!
  end

  def primary_general_agency_staff_role
    @general_agency_staff_role = FactoryBot.create(:general_agency_staff_role,
      benefit_sponsors_general_agency_profile_id: general_agency_profile.id, is_primary: true)
  end

  def general_agency_organization(legal_name = nil, *traits)
    attributes = traits.extract_options!
    traits.push(:with_general_agency_profile)
    @general_agency_organization ||= {}

    if legal_name.blank?
      if @general_agency_organization.empty?
        @general_agency_organization[:default] ||= FactoryBot.create(:benefit_sponsors_organizations_general_organization,
                                                                *traits,
                                                                attributes.merge(site: site))
      else
        @general_agency_organization.values.first
      end
    else
      @general_agency_organization[legal_name] ||= FactoryBot.create(:benefit_sponsors_organizations_general_organization,
                                                                *traits,
                                                                attributes.merge(site: site))
    end
  end

  def general_agency_profile(legal_name = nil)
    @general_agency_profile = general_agency_organization(legal_name).general_agency_profile if general_agency_organization(legal_name).present?
  end

  def assign_staff_to_general_agency(staff_name, legal_name)
    general_agency_profile = general_agency_profile(legal_name)
    person = FactoryBot.create(:person, :with_work_email, first_name: staff_name.split(/\s/)[0], last_name: staff_name.split(/\s/)[1])
    primary_general_agency_staff_role = create(:general_agency_staff_role, aasm_state: :active, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, is_primary: true)
    person.general_agency_staff_roles << primary_general_agency_staff_role
    @ga_staff = create(:user, person: person, email: people[staff_name][:email], password: people[staff_name][:password], password_confirmation: people[staff_name][:password])
    @ga_staff.roles = ['general_agency_staff']
    @ga_staff.update_attributes(last_portal_visited: "/benefit_sponsors/profiles/general_agencies/general_agency_profiles/#{general_agency_profile.id}")
  end

  def create_ga_staff(staff_name, legal_name, user)
    general_agency_profile = general_agency_profile(legal_name)
    person = FactoryBot.create(:person, first_name: staff_name.split(/\s/)[0], last_name: staff_name.split(/\s/)[1], user: user)
    primary_general_agency_staff_role = create(:general_agency_staff_role, aasm_state: :active, benefit_sponsors_general_agency_profile_id: general_agency_profile.id, is_primary: true)
    person.general_agency_staff_roles << primary_general_agency_staff_role
    user.roles = ['general_agency_staff']
    user.update_attributes(last_portal_visited: "/benefit_sponsors/profiles/general_agencies/general_agency_profiles/#{general_agency_profile.id}")
  end
end

World(GeneralAgencyWorld)

Given(/^there is a General Agency exists for (.*?)$/) do |general_agency_name|
  general_agency_organization general_agency_name, legal_name: general_agency_name, dba: general_agency_name

  general_agency_profile(general_agency_name).update_attributes!(aasm_state: 'is_approved')
end

And(/^the staff (.*?) is primary ga staff for (.*?)$/) do |staff_name, general_agency_name|
  assign_staff_to_general_agency(staff_name, general_agency_name)
end

And /^a general agency, pending approval, exists$/ do
  assign_roles_to_general_agency
  staff = general_agency_organization.general_agency_profile.general_agency_staff_roles.last
  staff.person.emails.last.update(kind: 'work')
end

Then /^they should see the name of staff$/ do
  full_name = general_agency_organization.general_agency_profile.general_agency_staff_roles.last.person.full_name
  expect(page).to have_content("General Agency Staff")
  expect(page).to have_content(general_agency_organization.legal_name)
  expect(page).to have_content(full_name)
  screenshot("general_agency_staff_list")

  click_link full_name
end

Then /^the general agency should receive an email$/ do
  staff = general_agency_organization.general_agency_profile.general_agency_primary_staff
  open_email(staff.email_address)
end

Given /^a general agency, approved, awaiting account creation, exists$/ do
  assign_roles_to_general_agency
  staff = general_agency_organization.general_agency_profile.general_agency_primary_staff
  staff.person.emails.last.update(kind: 'work')
  staff.approve!
end

When /^the HBX admin visits the link received in the approval email$/ do
  staff = general_agency_organization.general_agency_profile.general_agency_primary_staff
  email_address = staff.email_address

  open_email(email_address)
  expect(current_email.to).to eq([email_address])

  invitation_link = links_in_email(current_email).first
  invitation_link.sub!(/http\:\/\/127\.0\.0\.1\:3000/, '')
  visit(invitation_link)
end

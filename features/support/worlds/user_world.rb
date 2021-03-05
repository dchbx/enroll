module UserWorld
  def employee(employer=nil)
    if @employee
      @employee
    else
      employer_staff_role = FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer.profiles.first.id)
      person = FactoryBot.create(:person, employer_staff_roles:[employer_staff_role])
      @employee = FactoryBot.create(:user, :person => person)
    end
  end

  def employer_staff
    if @employer_staff
      @employer_staff
    else
      @employer_staff = FactoryBot.create(:user, :employer_staff)
    end
  end

  def employee_role
    if @employee_role
      @employee_role
    else
      @employee_role = FactoryBot.create(:user, :employee)
    end
  end

  # def users_by_role(role_name = nil, *traits)
  #  attributes = traits.extract_options!
  #  @users_by_role ||= {}

  #  if role_name.blank?
  #    if @users_by_role.empty?
  #      raise "No users by role present."
  #    else
  #      @users_by_role.values.first
  #    end
  #  else
  #    #define_permissions unless Permission.where(name: role_name).present?
  #    #role = Permission.where(name: role_name).first
  #    @users_by_role_name[role_name] ||= FactoryBot.create(:user, roles: [role_name])
  #  end
  # end
  
  # perhaps should be an array for suroles
  # example
  # if @admin_roles[subrole]
  def admin(subrole)
    if @admin
      @admin
    else
      subrole = subrole.parameterize.underscore
      hbx_profile_id = FactoryBot.create(:hbx_profile).id
      person = FactoryBot.create(:person)
      if subrole.blank?
        raise "No subrole was provided"
      end
      if Permission.where(name:subrole).present?
        permission = Permission.where(name: subrole).first
        permission.update_attributes(can_modify_plan_year: true)
        permission_id = permission.id
      else
        raise "No permission was found for subrole #{subrole}"
      end
      hbx_staff_role = HbxStaffRole.create!( person: person, permission_id: permission_id, subrole: subrole, hbx_profile_id: hbx_profile_id)
      @admin = FactoryBot.create(:user,:with_hbx_staff_role, :person => person)
    end
  end
end

World(UserWorld)

Given(/^that a user with a (.*?) role(?: with (.*?) subrole)? exists and (.*?) logged in$/) do |type, subrole, logged_in|
  case type
    when "Employer"
      user = employee(employer)
    when "Broker"
      # in features/step_definitions/broker_employee_quote_steps.rb BrokerWorld module
      user = broker
    when "HBX staff"
      user = admin(subrole)
    when 'Employer Role'
      user = employer_staff
    when 'Employee Role'
      user = employee_role
    else
      user = users_by_role(type)
  end
  case logged_in
    when 'is'
      login_as(user, :scope => :user)
    when 'is not'
      nil
  end
end

And(/^user with (.*?) role is (.*?)$/) do |type, locked_status|
  case type
    when "Employer"
      user = employee(employer)
    when "Broker"
      user = broker
    when "HBX staff"
      user = admin(subrole)
    when 'Employer Role'
      user = employer_staff
    when 'Employee Role'
      user = employee_role
  end
  case locked_status
  when 'locked'
    user.update_attributes(locked_at: Date.today)
  when 'unblocked'
    user.update_attributes(locked_at: nil)
  end
end

And(/^the user is on the Employer Index of the Admin Dashboard$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-employers').click
end

And(/^the user is on the Family Index of the Admin Dashboard$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-families').click
end

When(/^the user clicks Action for that Employer$/) do
  find('.dropdown.pull-right', text: 'Actions').click
end

Then(/^the user will see the Extend Open Enrollment button$/) do
  expect(page).to have_css('.btn.btn-xs', text: 'Extend Open Enrollment')
end

And(/^the user clicks the Plan Years button$/) do
  find('.btn.btn-xs', text: 'Plan Years').click
end

Then(/^the user will see the Plan Years button$/) do
  find('.btn.btn-xs', text: 'Plan Years', wait: 5).click
end

Then(/^the user will not see the Extend Open Enrollment button$/) do
  expect(page).to_not have_css('.btn.btn-xs', text: 'Extend Open Enrollment')
end

When(/^the user clicks Extend Open Enrollment$/) do
  find('.btn.btn-xs', text: 'Extend Open Enrollment').click
end

When(/^the user clicks Edit Open Enrollment$/) do
  find('a.btn.btn-primary.btn-sm', text: 'EDIT OPEN ENROLLMENT').click
end

Then(/^the user clicks Extend Open Enrollment button$/) do
  find('input[value="Extend Open Enrollment"]').click
end

Then(/^the user enters a new open enrollment end date$/) do
  input = find('input.hasDatepicker')
  input.set(Date.today+1.week)
end

Then(/^the user will see the Create Plan Year button$/) do
  expect(page).to have_css('.btn.btn-xs', text: 'Create Plan Year')
end

Then(/^the user will not see the Create Plan Year button$/) do
  expect(page).to_not have_css('.btn.btn-xs', text: 'Create Plan Year')
end

When(/^the user clicks the Create Plan Year button for this Employer$/) do
  find('.btn.btn-xs', text: 'Create Plan Year').click
end

Then(/^the user will see the Create Plan Year option row$/) do
  expect(page).to have_css('label', text: 'Effective Start Date')
  expect(page).to have_css('label', text: 'Effective End Date')
  expect(page).to have_css('label', text: 'Full Time Employees')
  expect(page).to have_css('label', text: 'Open Enrollment Start Date')
  expect(page).to have_css('label', text: 'Open Enrollment End Date')
end

Then(/^the user selects an Effective Start Date from the Create Plan Year form$/) do
  first_element = find("#baStartDate > option:nth-child(2)").text
  select(first_element, :from => "baStartDate")
end

When(/^the user selects an input in the Effective Start date drop down$/) do
  find('a', text: 'Effective Start Date')
end

When(/^the user completely fills out the Create Plan Year Form$/) do
  fill_in_admin_create_plan_year_form
end

When(/^the user partially fills out the Create Plan Year Form$/)  do
  fill_in_partial_create_plan_year_form
end

When(/^the user clicks the X icon on the Create Plan Year form$/) do
  find('#closeBAForm').click
end

Then(/^the Effective End Date will populate with a date equal to one year minus (\d+) day from the Effective Start Date$/) do |arg1|
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the Effective End Date will not be editable\.$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the user will( not)? see the Change FEIN button$/) do |visible|
  if visible.blank?
     expect(page).to have_css('.btn.btn-xs', text: 'Change FEIN')
  else
     expect(page).to_not have_css('.btn.btn-xs', text: 'Change FEIN')
   end
end

Then(/^the user will( not)? see the Force Publish button$/) do |visible|
  if visible.blank?
    expect(page).to have_css('.btn.btn-xs', text: 'Force Publish')
  else
    expect(page).to_not have_css('.btn.btn-xs', text: 'Force Publish')
  end
end

Then(/^the user will( not)? see the Edit DOB SSN button$/) do |visible|
  if visible.blank?
    find_link('Edit DOB / SSN').visible?
  else
    find_link('Edit DOB / SSN').visible? == false
  end
end


And(/^system date is between submission deadline & OE End date$/) do
  allow(TimeKeeper).to receive(:date_of_record).and_return((initial_application.open_enrollment_period.max - 1.day))
end

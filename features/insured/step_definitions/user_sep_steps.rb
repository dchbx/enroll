module UserSepWorld
  def user(*traits)
    attributes = traits.extract_options!
    @user ||= FactoryGirl.create :user, *traits, attributes
  end
end

World(UserSepWorld)

Given(/^a user exists$/) do
  user :consumer, :with_family, :ridp_verified
  visit "/users/sign_in"
end

Given(/^the user signs in$/) do
  fill_in 'user_login', with: user.oim_id
  fill_in 'user_password', with: user.password
  click_button 'Sign in'
  screenshot "entered credentials"
end

Given(/^has already enrolled for SEP$/) do
  FactoryGirl.create :hbx_profile
  user.person.consumer_role = FactoryGirl.build(:consumer_role, person: user.person, aasm_state: 'fully_verified')
  user.person.save
  user.primary_family.special_enrollment_periods.push FactoryGirl.build(:special_enrollment_period, qle_on: Date.yesterday, effective_on_kind: ['first_of_month'])
  user.primary_family.save
end

When(/^the user goes to the families homepage$/) do
  screenshot "here now"
  visit '/families/home?tab=home'
  screenshot "end"
end

When(/^the user clicks Shop for plans button$/) do
  click_button 'Shop for Plans'
  screenshot "progress"
end

Then(/^the user should be able to use their existing SEP$/) do
  wait_for_ajax
  screenshot "final step"
  expect(page).to have_content('Shop with existing SEP')
end

# frozen_string_literal: true

class CreateAccount

  include RSpec::Matchers
  include Capybara::DSL

  def email_or_username
    '//input[@id="user_oim_id"]'
  end

  def password
    '//input[@id="user_password"]'
  end

  def password_confirmation
    '//input[@id="user_password_confirmation"]'
  end

  def email
    '//input[@id="user_email"]'
  end

  def password_did_not_match_error_msg
    '//div[@class="alert alert-danger"]'
  end

  def create_account_btn
    '//input[@value="Create Account"]'
  end

  def sign_in_existing_account
    '//a[text()="Sign In Existing Account"]'
  end
end
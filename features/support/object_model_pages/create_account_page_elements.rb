# frozen_string_literal: true

class CreateAccount
  def self.email_or_username
    find(:xpath, '//input[@id="user_oim_id"]')
  end

  def self.password
    find(:xpath, '//input[@id="user_password"]')
  end

  def self.password_confirmation
    find(:xpath, '//input[@id="user_password_confirmation"]')
  end

  def self.email
    find(:xpath, '//input[@id="user_email"]')
  end

  def self.password_did_not_match_error_msg
    find(:xpath, '//div[@class="alert alert-danger"]')
  end

  def self.create_account_btn
    find(:xpath, '//input[@value="Create Account"]')
  end

  def self.sign_in_existing_account
    find(:xpath, '//a[text()="Sign In Existing Account"]')
  end
end
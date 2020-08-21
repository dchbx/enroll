# frozen_string_literal: true

class SignIn
  def self.sign_in_text
    find(:xpath, '//h1[text()="Sign In"]')
  end

  def self.username
    find(:xpath, '//input[@id="user_login"]')
  end

  def self.password
    find(:xpath, '//input[@id="user_password"]')
  end

  def self.remember_me_checkbox
    find(:xpath, '//input[@id="user_remember_me"]')
  end

  def self.sign_in_btn
    find(:xpath, '//input[@class="btn btn-primary sign-in-btn"]')
  end

  def self.forgot_your_password_btn
    find(:xpath, '//a[text()="Forgot your password?"]')
  end

  def self.create_account_btn
    find(:xpath, '//a[text()="Create account"]')
  end
end

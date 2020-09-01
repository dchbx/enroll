# frozen_string_literal: true

class SignIn

  include RSpec::Matchers
  include Capybara::DSL
  
  def sign_in_text
    find(:xpath, '//h1[text()="Sign In"]')
  end

  def username
    find(:xpath, '//input[@id="user_login"]')
  end

  def password
    find(:xpath, '//input[@id="user_password"]')
  end

  def remember_me_checkbox
    find(:xpath, '//input[@id="user_remember_me"]')
  end

  def sign_in_btn
    find(:xpath, '//input[@class="btn btn-primary sign-in-btn"]')
  end

  def forgot_your_password_btn
    find(:xpath, '//a[text()="Forgot your password?"]')
  end

  def create_account_btn
    find(:xpath, '//a[text()="Create account"]')
  end
end

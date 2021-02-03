# frozen_string_literal: true

#users/sign_in
class SignIn

  def self.username
    'user_login'
  end

  def self.password
    'user[password]'
  end

  def self.remember_me_checkbox
    '#user_remember_me'
  end

  def self.sign_in_btn
    '.sign-in-btn'
  end

  def self.forgot_your_password_btn
    'a[href="/users/password/new"]'
  end

  def self.create_account_btn
    'a[href="/users/sign_up"]'
  end
end

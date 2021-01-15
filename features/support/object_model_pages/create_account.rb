# frozen_string_literal: true

#users/sign_up
class CreateAccount

  def self.email_or_username
    'user_oim_id'
  end

  def self.password
    'user[password]'
  end

  def self.password_confirmation
    'user[password_confirmation]'
  end

  def self.email
    'user[email]'
  end

  def self.create_account_btn
    '.create-account-btn'
  end

  def self.sign_in_link
    '.btn-link'
  end
end
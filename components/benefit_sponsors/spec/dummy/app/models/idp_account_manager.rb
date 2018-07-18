class IdpAccountManager
  attr_accessor :provider
  include Singleton

  CURAM_NAVIGATION_FLAG = "2"
  ENROLL_NAVIGATION_FLAG = "1"

  def self.create_account(email, username, password, personish, account_role, timeout = 15)
  end
end

require 'securerandom'

class IdpAccountManager
  attr_accessor :provider
  include Singleton

  CURAM_NAVIGATION_FLAG = "2"
  ENROLL_NAVIGATION_FLAG = "1"

  def initialize
    @provider = AmqpSource
  end

  def check_existing_account(personish, timeout = 5)
    provider.check_existing_account(
      personish.first_name,
      personish.last_name,
      personish.ssn,
      personish.dob,
      timeout
    )
  end

  def create_account(email, username, password, personish, account_role, timeout = 15)
    account_role_val = "individual"
    system_flag = "1"
    case account_role
    when "assisted_individual"
      account_role_val = "individual"
      system_flag = "2"
    when "broker"
      account_role_val = "broker"
    else
      account_role_val = account_role
    end
    account_params = {
      :email => email,
      :username => username,
      :password => password,
      :first_name => personish.first_name,
      :last_name => personish.last_name,
      :account_role => account_role_val,
      :system_flag => system_flag
    }
    ForgeRock.new(params, personish.user).create_forgerock_account
    provider.create_account(account_params, timeout)
  end

  def update_navigation_flag(lu, email, flag)
    ForgeRock.new({username: lu, email: email, system_flag: flag}, "").update_forgerock_account
    provider.update_navigation_flag(lu, email, flag)
  end

  def self.set_provider(prov)
    self.instance.provider = prov
  end

  def self.slug!
    self.set_provider(SlugSource)
  end

  def self.update_navigation_flag(lu, email, flag)
    self.instance.update_navigation_flag(lu, email, flag)
  end

  def self.check_existing_account(personish, timeout = 5)
    self.instance.check_existing_account(personish, timeout)
  end

  def self.create_account(email, username, password, personish, account_role, timeout = 15)
    self.instance.create_account(email, username, password, personish, account_role, timeout)
  end

  class AmqpSource
    extend Acapi::Notifiers
    def self.check_existing_account(fname,lname,ssn,dob, timeout = 5)
      found_users = CuramUser.search_for(
        fname,
        lname,
        ssn,
        dob
      )
      case found_users.count
      when 1
        :existing_account
      when 0
        :not_found
      else
        :too_many_matches
      end
    end

    def self.update_navigation_flag(legacy_username, email, flag)
      lu = (legacy_username.blank? ? email : legacy_username)
      notify("acapi.info.events.account_management.update_navigation_flag",{ :email => email, :flag => flag, :legacy_username => lu})
    end

    def self.create_account(args, timeout = 5)
      notify("acapi.info.events.account_management.creation_requested", args)
    end

    def self.invoke_service(key, args, timeout = 5, &blk)
      begin
        request_result = Acapi::Requestor.request(key, args, timeout)
        result_code = request_result.stringify_keys["return_status"].to_s
        case result_code
        when "503"
          :service_unavailable
        else
          blk.call(result_code)
        end
      rescue Timeout::Error => e
        :service_unavailable
      end
    end
  end

  class SlugSource
    def self.update_navigation_flag(legacy_username, email, flag)
    end

    def self.create_account(args, timeout = 5)
      :created
    end

    def self.check_existing_account(fname, lname, ssn, dob, timeout = 5)
      :not_found
    end
  end
end

# Fix slug setting on request reload
unless Rails.env.production?
  IdpAccountManager.slug!
end

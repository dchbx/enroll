# frozen_string_literal: true

#benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/broker_id
class BrokerHomePage

  def self.edit_broker_agency_profile_btn
    'a[class="btn btn-primary  interaction-click-control-edit-broker-agency-profile"]'   
  end

  def self.add_broker_staff_role_btn
    '#add_staff'
  end

  def self.staff_first_name
    'staff_first_name'
  end

  def self.staff_last_name
    'staff_last_name'
  end

  def self.staff_dob
    'staff_dob'
  end

  def self.save_btn
    'button[type="submit"]'
  end

  def self.cancel_btn
    'a[class="btn btn-default pull-left"]'
  end

  def self.employers_tab
    '#employers-tab'
  end

  def self.families_tab
    '#families-tab'
  end

  def self.general_agencies_tab
    '.interaction-click-control-general-agencies span'
  end

  def self.home_tab
    '#home-tab'
  end

  def self.broker_mail_tab
    '#inbox-tab'
  end

  def self.logout_btn
    'a[class="header-text interaction-click-control-logout"]'
  end

  def self.help_btn
    '.header-text.interaction-click-control-help'
  end
end
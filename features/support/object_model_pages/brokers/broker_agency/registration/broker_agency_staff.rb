# frozen_string_literal: true

#benefit_sponsors/profiles/registrations/new?profile_type=broker_agency
class BrokerAgencyStaffRegistration

  def self.broker_agency_staff_tab
    '#ui-id-2'
  end

  def self.first_name
    'staff[first_name]'
  end

  def self.last_name
    'staff[last_name]'
  end

  def self.dob
    'staff[dob]'
  end

  def self.email
    'staff[email]'
  end

  def self.select_your_broker
    'staff_agency_search'
  end

  def self.search_btn
    '.btn-select'
  end

  def self.submit_application_btn
    '#broker-staff-btn'
  end

end
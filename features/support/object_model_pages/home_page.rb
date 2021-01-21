# frozen_string_literal: true

#dchbx.org
class HomePage

  def self.employee_portal_btn
    'a[href="/insured/employee/privacy"]'
  end

  def self.consumer_family_portal_btn
    'a[href="/insured/consumer_role/privacy?uqhp=true"]'
  end

  def self.assisted_consumer_family_portal_btn
    'a[href="/insured/consumer_role/privacy?aqhp=true"]'
  end

  def self.returning_user_btn
    'a[href="/families/home"]'
  end

  def self.employer_portal_btn
    'a[href="/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor"]'
  end

  def self.broker_agency_portal_btn
    'a[href="/benefit_sponsors/profiles/registrations/new?portal=true&profile_type=broker_agency"]'
  end

  def self.general_agency_portal_btn
    'a[href="/benefit_sponsors/profiles/registrations/new?portal=true&profile_type=general_agency"]'
  end

  def self.hbx_portal_btn
    '.hbx-portal'
  end

  def self.broker_registration_btn
    '.broker-registration'
  end

  def self.general_agency_registration_btn
    'a[href="/benefit_sponsors/profiles/registrations/new?profile_type=general_agency"]'
  end
end
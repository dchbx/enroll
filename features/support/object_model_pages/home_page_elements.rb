# frozen_string_literal: true

class HomePage
  def self.dc_health_link_logo
    find(:xpath, '//a[@class="navbar-brand pr-3 pt-3 pb-3"]/img')
  end

  def self.welcome_text
    find(:xpath, '//h1[@class="text-center heading-text mb-0 pt-5 welcome-text"]/strong')
  end

  def self.employee_portal_btn
    find(:xpath, '//a[text()="Employee Portal"]')
  end

  def self.consumer_family_portal_btn
    find(:xpath, '//a[text()="Consumer/Family Portal"]')
  end

  def self.assisted_consumer_family_portal_btn
    find(:xpath, '//a[text()="Assisted Consumer/Family Portal"]')
  end

  def self.returning_user_btn
    find(:xpath, '//a[text()="Returning User"]')
  end

  def self.employer_portal_btn
    find(:xpath, '//a[text()="Employer Portal"]')
  end

  def self.broker_agency_portal_btn
    find(:xpath, '//a[text()="Broker Agency Portal"]')
  end

  def self.general_agency_portal_btn
    find(:xpath, '//a[text()="General Agency Portal"]')
  end

  def self.hbx_portal_btn
    find(:xpath, '//a[text()="HBX Portal"]')
  end

  def self.broker_registration_btn
    find(:xpath, '//a[text()="Broker Registration"]')
  end

  def self.general_agency_registration_btn
    find(:xpath, '//a[text()="General Agency Registration"]')
  end
end

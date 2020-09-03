# frozen_string_literal: true

class HomePage

  include RSpec::Matchers
  include Capybara::DSL

  def dc_health_link_logo
    '//a[@class="navbar-brand pr-3 pt-3 pb-3"]/img'
  end

  def welcome_text
    '//h1[@class="text-center heading-text mb-0 pt-5 welcome-text"]/strong'
  end

  def employee_portal_btn
    '//a[text()="Employee Portal"]'
  end

  def consumer_family_portal_btn
    '//a[text()="Consumer/Family Portal"]'
  end

  def assisted_consumer_family_portal_btn
    '//a[text()="Assisted Consumer/Family Portal"]'
  end

  def returning_user_btn
    '//a[text()="Returning User"]'
  end

  def employer_portal_btn
    '//a[text()="Employer Portal"]'
  end

  def broker_agency_portal_btn
    '//a[text()="Broker Agency Portal"]'
  end

  def general_agency_portal_btn
    '//a[text()="General Agency Portal"]'
  end

  def hbx_portal_btn
    '//a[text()="HBX Portal"]'
  end

  def broker_registration_btn
    '//a[text()="Broker Registration"]'
  end

  def general_agency_registration_btn
    '//a[text()="General Agency Registration"]'
  end
end
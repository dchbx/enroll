# frozen_string_literal: true

class BrokerAgencyStaffRegistration

  include RSpec::Matchers
  include Capybara::DSL

  def broker_agency_staff_tab
    '//a[@id="ui-id-2"]'
  end

  def first_name
    '(//input[@id="inputFirstname"])[2]'
  end

  def last_name
    '(//input[@id="inputLastname"])[2]'
  end

  def dob
    '//input[@id="inputStaffDOB"]'
  end

  def email
    '(//input[@id="inputEmail"])[2]'
  end

  def select_your_broker
    '//input[@id="staff_agency_search"]'
  end

  def search_btn
    '//a[@class="btn btn-select search"]'
  end

  def submit_application_btn
    '//button[@id="broker-staff-btn"]'
  end

  def no_broker_agencies_found_error_msg
    '//span[text()=" No Broker Agencies Found "]'
  end
end
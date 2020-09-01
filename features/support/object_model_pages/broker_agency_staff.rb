# frozen_string_literal: true

class BrokerAgencyStaffRegistration

  include RSpec::Matchers
  include Capybara::DSL

  def broker_agency_staff_tab
    find(:xpath, '//a[@id="ui-id-2"]')
  end

  def first_name
    find(:xpath, '(//input[@id="inputFirstname"])[2]')
  end

  def last_name
    find(:xpath, '(//input[@id="inputLastname"])[2]')
  end

  def dob
    find(:xpath, '//input[@id="inputStaffDOB"]')
  end

  def email
    find(:xpath, '(//input[@id="inputEmail"])[2]')
  end

  def select_your_broker
    find(:xpath, '//input[@id="staff_agency_search"]')
  end

  def search_btn
    find(:xpath, '//a[@class="btn btn-select search"]')
  end

  def submit_application_btn
    find(:xpath, '//button[@id="broker-staff-btn"]')
  end

  def no_broker_agencies_found_error_msg
    find(:xpath, '//span[text()=" No Broker Agencies Found "]')
  end
end
# frozen_string_literal: true

class GeneralAgencyStaffRegistration

  include RSpec::Matchers
  include Capybara::DSL

  def general_agency_staff_tab
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

  def select_your_general_agency
    find(:xpath, '//input[@id="staff_agency_search"]')
  end

  def search_btn
    find(:xpath, '//a[@class="btn btn-select search"]')
  end

  def submit_application_btn
    find(:xpath, '//button[@id="general-agency-staff-btn"]')
  end

  def no_general_agencies_found_error_msg
    find(:xpath, '//span[text()=" No General Agencies Found "]')
  end

  def select_this_general_agency_btn
    find(:xpath, '//a[@class="btn btn-primary select-general-agency"]')
  end
end
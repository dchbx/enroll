# frozen_string_literal: true

class GeneralAgencyRegistration

  include RSpec::Matchers
  include Capybara::DSL

  def general_agency_tab
    find(:xpath, '//a[@id="ui-id-1"]')
  end

  def first_name
    find(:xpath, '//input[@id="inputFirstname"]')
  end

  def last_name
    find(:xpath, '//input[@id="inputLastname"]')
  end

  def ga_dob
    find(:xpath, '//input[@id="inputDOB"]')
  end

  def email
    find(:xpath, '//input[@id="inputEmail"]')
  end

  def npn
    find(:xpath, '//input[@id="inputNPN"]')
  end

  def legal_name
    find(:xpath, '//input[@id="validationCustomLegalName"]')
  end

  def dba
    find(:xpath, '//input[@id="validationCustomdba"]')
  end

  def fein
    find(:xpath, '//input[@id="inputFein"]')
  end

  def practice_area_dropdown
    find(:xpath, '//select[@id="agency_organization_profile_attributes_market_kind"]')
  end

  def select_languages
    find(:xpath, '//select[@id="broker_agency_language_select"]')
  end

  def evening_hours_checkbox
    find(:xpath, '//input[@id="agency_organization_profile_attributes_working_hours"]')
  end

  def accept_new_client_checkbox
    find(:xpath, '//input[@id="agency_organization_profile_attributes_accept_new_clients"]')
  end

  def address
    find(:xpath, '//input[@id="inputAddress1"]')
  end

  def kind_dropdown
    find(:xpath, '//select[@id="kindSelect"]')
  end

  def address2
    find(:xpath, '//input[@id="agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_address_2"]')
  end

  def city
    find(:xpath, '//input[@id="agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_city"]')
  end

  def state_dropdown
    find(:xpath, '//select[@id="inputState"]')
  end

  def zip
    find(:xpath, '//input[@id="inputZip"]')
  end

  def area_code
    find(:xpath, '//input[@id="inputAreacode"]')
  end

  def number
    find(:xpath, '//input[@id="inputNumber"]')
  end

  def add_office_location_btn
    find(:xpath, '//a[@id="addOfficeLocation"]')
  end

  def create_general_agency_btn
    find(:xpath, '//input[@id="general-btn"]')
  end
end
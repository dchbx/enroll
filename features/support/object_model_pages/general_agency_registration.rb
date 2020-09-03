# frozen_string_literal: true

class GeneralAgencyRegistration

  include RSpec::Matchers
  include Capybara::DSL

  def general_agency_tab
    '//a[@id="ui-id-1"]'
  end

  def first_name
    '//input[@id="inputFirstname"]'
  end

  def last_name
    '//input[@id="inputLastname"]'
  end

  def ga_dob
    '//input[@id="inputDOB"]'
  end

  def email
    '//input[@id="inputEmail"]'
  end

  def npn
    '//input[@id="inputNPN"]'
  end

  def legal_name
    '//input[@id="validationCustomLegalName"]'
  end

  def dba
    '//input[@id="validationCustomdba"]'
  end

  def fein
    '//input[@id="inputFein"]'
  end

  def practice_area_dropdown
    '//select[@id="agency_organization_profile_attributes_market_kind"]'
  end

  def select_languages
    '//select[@id="broker_agency_language_select"]'
  end

  def evening_hours_checkbox
    '//input[@id="agency_organization_profile_attributes_working_hours"]'
  end

  def accept_new_client_checkbox
    '//input[@id="agency_organization_profile_attributes_accept_new_clients"]'
  end

  def address
    '//input[@id="inputAddress1"]'
  end

  def kind_dropdown
    '//select[@id="kindSelect"]'
  end

  def address2
    '//input[@id="agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_address_2"]'
  end

  def city
    '//input[@id="agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_city"]'
  end

  def state_dropdown
    '//select[@id="inputState"]'
  end

  def zip
    '//input[@id="inputZip"]'
  end

  def area_code
    '//input[@id="inputAreacode"]'
  end

  def number
    '//input[@id="inputNumber"]'
  end

  def add_office_location_btn
    '//a[@id="addOfficeLocation"]'
  end

  def create_general_agency_btn
    '//input[@id="general-btn"]'
  end
end
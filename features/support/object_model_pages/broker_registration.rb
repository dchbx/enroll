# frozen_string_literal: true

class BrokerRegistration

  include RSpec::Matchers
  include Capybara::DSL

  def broker_registration_form
    find(:xpath, '//form[@id="broker_registration_form"]')
  end  

  def broker_tab
    find(:xpath, '//a[@id="ui-id-1"]')
  end

  def first_name
    find(:xpath, '//label[text()=" First name *"]/following-sibling::input')
  end

  def last_name
    find(:xpath, '//label[text()=" Last name *"]/following-sibling::input')
  end

  def broker_dob
    find(:xpath, '//input[@id="inputDOB"]')
  end

  def email
    find(:xpath, '(//input[@id="inputEmail"])[1]')
  end

  def npn
    find(:xpath, '//input[@id="inputNPN"]')
  end

  def broker_agency_inf_text
    find(:xpath, '//h4[@class="mb-2"]/preceding-sibling::legend')
  end

  def legal_name
    find(:xpath, '//input[@id="validationCustomLegalName"]')
  end

  def dba
    find(:xpath, '//input[@id="validationCustomdba"]')
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

  def create_broker_agency_btn
    find(:xpath, '//input[@id="broker-btn"]')
  end
  
end

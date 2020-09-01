# frozen_string_literal: true

class BrokerRegistration

  def self.broker_registration_form
    binding.pry
    find(:xpath, '//form[@id="broker_registration_form"]')
  end  

  def self.broker_tab
    find(:xpath, '//a[@id="ui-id-1"]')
  end

  def self.first_name
    find(:xpath, '//label[text()=" First name *"]/following-sibling::input')
  end

  def self.last_name
    find(:xpath, '//label[text()=" Last name *"]/following-sibling::input')
  end

  def self.broker_dob
    find(:xpath, '//input[@id="inputDOB"]')
  end

  def self.email
    find(:xpath, '(//input[@id="inputEmail"])[1]')
  end

  def self.npn
    find(:xpath, '//input[@id="inputNPN"]')
  end

  def self.broker_agency_inf_text
    find(:xpath, '//h4[@class="mb-2"]/preceding-sibling::legend')
  end

  def self.legal_name
    find(:xpath, '//input[@id="validationCustomLegalName"]')
  end

  def self.dba
    find(:xpath, '//input[@id="validationCustomdba"]')
  end

  def self.practice_area_dropdown
    find(:xpath, '//select[@id="agency_organization_profile_attributes_market_kind"]')
  end

  def self.select_languages
    find(:xpath, '//select[@id="broker_agency_language_select"]')
  end

  def self.evening_hours_checkbox
    find(:xpath, '//input[@id="agency_organization_profile_attributes_working_hours"]')
  end

  def self.accept_new_client_checkbox
    find(:xpath, '//input[@id="agency_organization_profile_attributes_accept_new_clients"]')
  end

  def self.address
    find(:xpath, '//input[@id="inputAddress1"]')
  end

  def self.kind_dropdown
    find(:xpath, '//select[@id="kindSelect"]')
  end

  def self.address2
    find(:xpath, '//input[@id="agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_address_2"]')
  end

  def self.city
    find(:xpath, '//input[@id="agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_city"]')
  end

  def self.state_dropdown
    find(:xpath, '//select[@id="inputState"]')
  end

  def self.zip
    find(:xpath, '//input[@id="inputZip"]')
  end

  def self.area_code
    find(:xpath, '//input[@id="inputAreacode"]')
  end

  def self.number
    find(:xpath, '//input[@id="inputNumber"]')
  end

  def self.add_office_location_btn
    find(:xpath, '//a[@id="addOfficeLocation"]')
  end

  def self.create_broker_agency_btn
    find(:xpath, '//input[@id="broker-btn"]')
  end
  
end

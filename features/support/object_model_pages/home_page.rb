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

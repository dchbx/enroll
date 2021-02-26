# frozen_string_literal: true

# benefit_sponsors/profiles/registrations/new?profile_type=broker_agency
class BrokerRegistration

  def self.broker_registration_form
    '#broker_registration_form'
  end

  def self.broker_tab
    '#ui-id-1'
  end

  def self.first_name
    'inputFirstname'
  end

  def self.last_name
    'inputLastname'
  end

  def self.broker_dob
    'agency[staff_roles_attributes][0][dob]'
  end

  def self.email
    'inputEmail'
  end

  def self.npn
    'inputNPN'
  end

  def self.legal_name
    'validationCustomLegalName'
  end

  def self.dba
    'validationCustomdba'
  end

  def self.practice_area_dropdown
    'agency_organization_profile_attributes_market_kind'
  end

  def self.select_languages
    'broker_agency_language_select'
  end

  def self.evening_hours_checkbox
    '#agency_organization_profile_attributes_working_hours'
  end

  def self.accept_new_client_checkbox
    '#agency_organization_profile_attributes_accept_new_clients'
  end

  def self.address
    'inputAddress1'
  end

  def self.kind_dropdown
    'kindSelect'
  end

  def self.address2
    'agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_address_2'
  end

  def self.city
    'agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_city'
  end

  def self.state_dropdown
    'inputState'
  end

  def self.zip
    'inputZip'
  end

  def self.area_code
    'inputAreacode'
  end

  def self.number
    'inputNumber'
  end

  def self.add_office_location_btn
    '#addOfficeLocation'
  end

  def self.create_broker_agency_btn
    '#broker-btn'
  end

  def self.registration_submitted_succesful_message
    'Your registration has been submitted. A response will be sent to the email address you provided once your application is reviewed.'
  end

end
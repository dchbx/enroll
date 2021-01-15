# frozen_string_literal: true

#benefit_sponsors/profiles/registrations/new?profile_type=general_agency
class GeneralAgencyRegistration

  def self.general_agency_tab
    '#ui-id-1'
  end

  def self.general_agency_staff_tab
    '#ui-id-2'
  end

  def self.first_name
    'agency[staff_roles_attributes][0][first_name]'
  end

  def self.last_name
    'agency[staff_roles_attributes][0][last_name]'
  end

  def self.dob
    'agency[staff_roles_attributes][0][dob]'
  end

  def self.email
    'agency[staff_roles_attributes][0][email]'
  end

  def self.npn
    'agency[staff_roles_attributes][0][npn]'
  end

  def self.legal_name
    'validationCustomLegalName'
  end

  def self.dba
    'validationCustomdba'
  end

  def self.fein
    'agency[organization][fein]'
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
    'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][address_1]'
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
    'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][state]'
  end

  def self.zip
    'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][zip]'
  end

  def self.area_code
    'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][area_code]'
  end

  def self.number
    'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][number]'
  end

  def self.add_office_location_btn
    '#addOfficeLocation'
  end

  def self.create_general_agency_btn
    '#general-btn'
  end
end
# frozen_string_literal: true

# This is to find attrs on registration page for cucumbers POM.
class Registration

  include RSpec::Matchers
  include Capybara::DSL

  def self.first_name
    '//input[@id="agency_staff_roles_attributes_0_first_name"]'
  end

  def self.last_name
    '//input[@id="agency_staff_roles_attributes_0_last_name"]'
  end

  def self.date_of_birth
    '//input[@id="inputDOB"]'
  end

  def self.email
    'agency_staff_roles_attributes_0_email'
  end

  def self.area_code_personal_information
    'agency_staff_roles_attributes_0_area_code'
  end

  def self.number_personal_information
    'agency[staff_roles_attributes][0][number]'
  end

  def self.legal_name
    'agency[organization][legal_name]'
  end

  def self.dba
    'agency[organization][dba]'
  end

  def self.fein
    'agency[organization][fein]'
  end

  def self.kind
    'agency[organization][entity_kind]'
  end

  def self.address
    'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][address_1]'
  end

  def self.kind_office_location_dropdown
    'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][kind]'
  end

  def self.address_two
    'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][address_2]'
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

  def self.area_code_office_location
    'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][area_code]'
  end

  def self.number_office_location
    'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][number]'
  end

  def self.add_office_location_btn
    '//a[@id="addOfficeLocation"]'
  end

  def self.contact_method_dropdown
    'agency[organization][profile_attributes][contact_method]'
  end

  def self.confirm_btn
    '//input[@class="btn btn-primary pull-right mt-2"]'
  end

end
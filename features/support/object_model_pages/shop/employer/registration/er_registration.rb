# frozen_string_literal: true

#benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor
class EmployerRegistration

  def self.first_name
    'agency[staff_roles_attributes][0][first_name]'
  end

  def self.last_name
    'agency[staff_roles_attributes][0][last_name]'
  end

  def self.date_of_birth
    'agency[staff_roles_attributes][0][dob]'
  end

  def self.email
    'agency[staff_roles_attributes][0][email]'
  end

  def self.area_code_personal_information
    'agency[staff_roles_attributes][0][area_code]'
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

  def self.kind_employer_information
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
    'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][city]'
  end

  def self.state_dropdown
    'inputState'
  end

  def self.zip
    'agency[organization][profile_attributes][office_locations_attributes][0][address_attributes][zip]'
  end

  def self.area_code_office_location
    'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][area_code]'
  end

  def self.number_office_location
    'agency[organization][profile_attributes][office_locations_attributes][0][phone_attributes][number]'
  end

  def self.add_office_location_btn
    'a[id="addOfficeLocation"]'
  end

  def self.contact_method_dropdown
    'agency[organization][profile_attributes][contact_method]'
  end

  def self.confirm_btn
    'input[class="btn btn-primary pull-right mt-2"]'
  end

end
# frozen_string_literal: true

#benefit_sponsors/profiles/registrations/broker_Id/edit
class BrokerEditProfilePage

  def self.first_name
    'agency_staff_roles_attributes_0_first_name'
  end
  
  def self.last_name
    'agency_staff_roles_attributes_0_last_name'
  end

  def self.dob
    'jq_datepicker_ignore_agency_staff_roles_attributes_0_dob'
  end

  def self.legal_name
    'agency_organization_legal_name'
  end

  def self.evening_weekends_hours_checkbox
    '#agency_organization_profile_attributes_working_hours'
  end

  def self.accept_new_clients_checkbox
    '#agency_organization_profile_attributes_accept_new_clients'
  end

  def self.address_1
    'agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_address_1'
  end

  def self.address_2
    'agency_organization_profile_attributes_office_locations_attributes_0_address_attributes_address_2'
  end

  def self.city
    'CITY'
  end

  def self.state_dropdown
    '#inputState'
  end

  def self.zip
    'ZIP'
  end

  def self.area_code
    'AREA CODE'
  end

  def self.number
    'NUMBER'
  end

  def self.address_kind_dropdown
    'select[class="form-control interaction-choice-control-kindselect"]'
  end

  def self.select_mailing
    'option[class="interaction-choice-control-kindselect-2"]'
  end

  def self.select_branch
    'option[class="interaction-choice-control-kindselect-3"]'
  end

  def self.select_primary
    'option[class="interaction-choice-control-kindselect-1"]'
  end

  def self.add_office_location
    '.btn.btn-default.pull-left.col-12.interaction-click-control-add-office-location'
  end

  def self.update_broker_agency
    'div[class="row no-buffer"] button'
  end

  def self.remove_address
    '.far.fa-trash-alt.fa-2x.role-trashcan'
  end

  def self.logout_btn
    '.header-text.interaction-click-control-logout'
  end
end
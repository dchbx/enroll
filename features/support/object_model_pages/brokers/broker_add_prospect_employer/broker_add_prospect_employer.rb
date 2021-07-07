# frozen_string_literal: true

#sponsored_benefits/organizations/plan_design_organizations/new?broker_agency_id=60e4460a297c6a786b63dd0d
class BrokerAddProspectEmployerPage
    
  def self.legal_name
    'organization_legal_name'
  end

  def self.dba
    'organization_dba'
  end

  def self.address_1
    'ADDRESS LINE 1'
  end

  def self.address_2
    'ADDRESS LINE 2'
  end

  def self.city
    'CITY'
  end

  def self.zip
    'ZIP'
  end

  def self.state_dropdown
    '#organization_office_locations_attributes_0_address_attributes_state'
  end

  def self.select_dc
    '.interaction-choice-control-organization-office-locations-attributes-0-address-attributes-state-10'
  end

  def self.select_va
    '.interaction-choice-control-organization-office-locations-attributes-0-address-attributes-state-51'
  end

  def self.area_code
    'AREA CODE'
  end

  def self.number
    'NUMBER'
  end

  def self.extension
    'EXTENSION'
  end

  def self.entity_kind_dropdown
    '#organization_entity_kind'
  end
    
  def self.select_tax_exempt_organization
    '.interaction-choice-control-organization-entity-kind-1'
  end
    
  def self.select_c_corporation
  '.interaction-choice-control-organization-entity-kind-2'
  end
    
  def self.select_s_corporation
    '.interaction-choice-control-organization-entity-kind-3'
  end
    
  def self.select_partnership
    '.interaction-choice-control-organization-entity-kind-4'
  end
    
  def self.select_limited_liability_corporation
    '.interaction-choice-control-organization-entity-kind-5'
  end
    
  def self.select_limited_liability_partnership
    '.interaction-choice-control-organization-entity-kind-6'
  end
    
  def self.select_household_employer
    '.interaction-choice-control-organization-entity-kind-7'
  end
    
  def self.select_governmental_employer
    '.interaction-choice-control-organization-entity-kind-8'
  end
    
  def self.select_foreign_embassy_or_consulate
    '.interaction-choice-control-organization-entity-kind-9'
  end

  def self.ofiice_location_dropdown
    '#organization_office_locations_attributes_0_address_attributes_kind'
  end

  def self.select_primary
    '.interaction-choice-control-organization-office-locations-attributes-0-address-attributes-kind-0'
  end

  def self.select_monthly
    'option[value="mailing"]'
  end

  def self.select_branch
    '.interaction-choice-control-organization-office-locations-attributes-0-address-attributes-kind-2'
  end

  def self.confirm_btn
    '.btn.btn-primary.pull-right.sm_full_width.interaction-click-control-confirm'
  end

  def self.add_office_location
    '.btn.btn-default.pull-left'
  end
end    
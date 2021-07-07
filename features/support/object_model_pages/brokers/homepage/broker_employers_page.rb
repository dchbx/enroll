# frozen_string_literal: true

#benefit_sponsors/profiles/broker_agencies/broker_agency_profiles/broker_id
class BrokerEmployersPage

  def self.add_prospect_employer_btn
    '.btn.btn-primary.prospective-employer'
  end

  def self.actions_dropdown
    '.dropdown.pull-right .btn.btn-default.dropdown-toggle'
  end

  def self.view_quote
    '.col-string.col-actions li:nth-child(1)'
  end

  def self.create_quote
    '.col-string.col-actions li:nth-child(2)'
  end

  def self.edit_employer_details
    '.col-string.col-actions li:nth-child(3)'
  end

  def self.remove_employer
    '.col-string.col-actions li:nth-child(4)'
  end

  def self.assign_general_agency
    '.col-string.col-actions li:nth-child(5)'
  end

  def self.all_tab
    'div[id="Tab:all"]'
  end

  def self.active_sponsors_tab
    'div[id="Tab:active_sponsors"]'
  end

  def self.inactive_sponsors_tab
    'div[id="Tab:inactive_sponsors"]'
  end

  def self.prospect_sponsors_tab
    'div[id="Tab:prospect_sponsors"]'
  end

  def self.bulk_actions_dropdown
    'div[class="btn-group buttons-bulk-actions"]'
  end

  def self.csv_tab
    'a[class="btn btn-default buttons-csv buttons-html5"]'
  end

  def self.excel_tab
    'a[class="btn btn-default buttons-excel buttons-html5"]'
  end

  def self.search
    '.dataTables_filter input'
  end

  def self.clear_search_btn
    '.datatable_clear.btn.btn-sm.btn-default'
  end

  def self.logout_btn
    '.header-text.interaction-click-control-logout'
  end
end
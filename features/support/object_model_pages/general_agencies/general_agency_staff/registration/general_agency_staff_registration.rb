# frozen_string_literal: true

#benefit_sponsors/profiles/registrations/new?profile_type=general_agency
class GeneralAgencyStaffRegistration

  def self.first_name
    'staff[first_name]'
  end

  def self.last_name
    'staff[last_name]'
  end

  def self.dob
    'staff[dob]'
  end

  def self.email
    'staff[email]'
  end

  def self.select_your_general_agency
    'staff[agency_search]'
  end

  def self.search_btn
    '.search'
  end

  def self.submit_application_btn
    '#general-agency-staff-btn'
  end
end
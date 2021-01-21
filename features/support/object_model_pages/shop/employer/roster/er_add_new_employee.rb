# frozen_string_literal: true

#employers/employer_profiles/5ff77ba896a4a17b76f892bc/census_employees/new?tab=employees
class EmployerAddNewEmployee

  def self.first_name
    'census_employee[first_name]'
  end

  def self.middle_name
    'census_employee[middle_name]'
  end

  def self.last_name
    'census_employee[last_name]'
  end

  def self.suffix_dropdown
    'div[id="employer_info"] span[class="label"]'
  end

  def self.date_of_birth
    'jq_datepicker_ignore_census_employee[dob]'
  end

  def self.ssn
    'census_employee[ssn]'
  end

  def self.male_radiobtn
    'label[for="census_employee_gender_male"] span'
  end

  def self.female_radiobtn
    'label[for="census_employee_gender_female"] span'
  end

  def self.hire_date
    'jq_datepicker_ignore_census_employee[hired_on]'
  end

  def self.is_owner_checkbox_yes
    'input[id="census_employee_is_business_owner"]'
  end

  def self.benefit_package_dropdown
    'div[class="module census-employee-fields forms"] span[class="label"]'
  end

  def self.enrolled_into_cobra_checkbox
    'input[id="census_employee_existing_cobra"]'
  end

  def self.address_line_one
    'census_employee[address_attributes][address_1]'
  end

  def self.address_line_two
    'census_employee[address_attributes][address_2]'
  end

  def self.city
    'census_employee[address_attributes][city]'
  end

  def self.state_dropdown
    'div[class="row row-form-wrapper no-buffer address-row"] span[class="label"]'
  end

  def self.zip
    'census_employee[address_attributes][zip]'
  end

  def self.kind_dropdown
    'div[id="email_info"] span'
  end

  def self.email
    'census_employee[email_attributes][address]'
  end

  def self.add_dependent_btn
    'a[class="add_fields btn btn-default btn-sm interaction-click-control-add-dependent"]'
  end

  def self.cancel_btn
    'a[class="btn btn-default btn-lg return_to_employee_roster interaction-click-control-cancel"]'
  end

  def self.create_employee_btn
    'button[class="btn btn-primary btn-lg interaction-click-control-create-employee"]'
  end
end
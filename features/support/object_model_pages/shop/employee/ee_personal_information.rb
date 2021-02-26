# frozen_string_literal: true

#insured/employee/search
class EmployeePersonalInformation

  def self.first_name
    'person[first_name]'
  end

  def self.middle_name
    'person[middle_name]'
  end

  def self.last_name
    'person[last_name]'
  end

  def self.suffix_dropdown
    'div[id="personal_info"] span[class="label"]'
  end

  def self.dob
    'jq_datepicker_ignore_person[dob]'
  end

  def self.social_security
    'person[ssn]'
  end

  def self.i_dont_have_an_ssn_checkbox
    'input[id="person_no_ssn"]'
  end

  def self.male_radiobtn
    'label[for="radio_male"] span'
  end

  def self.female_radiobtn
    'label[for="radio_female"] span'
  end

  def self.continue_btn
    'button[id="btn-continue"]'
  end
end
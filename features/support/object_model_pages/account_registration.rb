# frozen_string_literal: true

class AccountRegistration

  include RSpec::Matchers
  include Capybara::DSL

  def account_registration_link
    '//a[@class="interaction-click-control-account-registration"]'
  end

  def first_name
    '//input[@id="person_first_name"]'
  end

  def middle_name
    '//input[@id="person_middle_name"]'
  end

  def last_name
    '//input[@id="person_last_name"]'
  end

  def suffix_dropdown
    '//div[@class="selectric"]'
  end

  def need_coverage_yes_radiobtn
    '//label[@for="is_applying_coverage_true"]//span'
  end

  def need_coverage_no_radiobtn
    '//label[@for="is_applying_coverage_false"]//span'
  end

  def not_sure_link
    '//div[@class="col-md-2 left-seprator"]//a'
  end

  def dob
    '//input[@id="jq_datepicker_ignore_person_dob"]'
  end

  def social_security
    '//input[@id="person_ssn"]'
  end

  def i_dont_have_an_ssn_checkbox
    '//input[@id="person_no_ssn"]'
  end

  def male_radiobtn
    '//span[text()="MALE"]'
  end

  def female_radiobtn
    '//span[text()="FEMALE"]'
  end

  def continue_btn
    '//span[text()="CONTINUE"]'
  end

  def thank_you_confirmation_message
    '//div[@class="alert alert-success alert-dismissible"]'
  end

  def previous_link
    '//a[@class="back interaction-click-control-previous"]'
  end
end
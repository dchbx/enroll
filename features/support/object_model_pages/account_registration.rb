# frozen_string_literal: true

class AccountRegistration

  include RSpec::Matchers
  include Capybara::DSL

  def account_registration_link
    find(:xpath, '//a[@class="interaction-click-control-account-registration"]')
  end

  def first_name
    find(:xpath, '//input[@id="person_first_name"]')
  end

  def middle_name
    find(:xpath, '//input[@id="person_middle_name"]')
  end

  def last_name
    find(:xpath, '//input[@id="person_last_name"]')
  end

  def suffix_dropdown
    find(:xpath, '//div[@class="selectric"]')
  end

  def need_coverage_yes_radiobtn
    find(:xpath, '//label[@for="is_applying_coverage_true"]//span')
  end

  def need_coverage_no_radiobtn
    find(:xpath, '//label[@for="is_applying_coverage_false"]//span')
  end

  def not_sure_link
    find(:xpath, '//div[@class="col-md-2 left-seprator"]//a')
  end

  def dob
    find(:xpath, '//input[@id="jq_datepicker_ignore_person_dob"]')
  end

  def social_security
    find(:xpath, '//input[@id="person_ssn"]')
  end

  def i_dont_have_an_ssn_checkbox
    find(:xpath, '//input[@id="person_no_ssn"]')
  end

  def male_radiobtn
    find(:xpath, '//span[text()="MALE"]')
  end

  def female_radiobtn
    find(:xpath, '//span[text()="FEMALE"]')
  end

  def continue_btn
    find(:xpath, '//span[text()="CONTINUE"]')
  end

  def thank_you_confirmation_message
    find(:xpath, '//div[@class="alert alert-success alert-dismissible"]')
  end

  def previous_link
    find(:xpath, '//a[@class="back interaction-click-control-previous"]')
  end
end
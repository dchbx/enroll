# frozen_string_literal: true

class PersonalInformation

  include RSpec::Matchers
  include Capybara::DSL

  def tell_us_about_yourself_link
    '//a[@class="interaction-click-control-tell-us-about-yourself"]'
  end

  def us_citizen_or_national_yes_radiobtn
    '//label[@for="person_us_citizen_true"]/span'
  end

  def us_citizen_or_national_no_radiobtn
    '//label[@for="person_us_citizen_false"]/span'
  end

  def naturalized_citizen_yes_radiobtn
    '//label[@for="person_naturalized_citizen_true"]/span'
  end

  def naturalized_citizen_no_radiobtn
    '//label[@for="person_naturalized_citizen_false"]/span'
  end

  def naturalized_citizen_not_sure_link
    '(//div[@class="col-md-2 not-sure-margin left-seprator"])[1]//a'
  end

  def naturalized_citizen_select_doc_dropdown
    '(//span[text()="Select document type"])[2]'
  end

  def immigration_status_yes_radiobtn
    '//label[@for="person_eligible_immigration_status_true"]/span'
  end

  def immigration_status_no_radiobtn
    '//label[@for="person_eligible_immigration_status_false"]/span'
  end

  def immigration_status_select_doc_dropdown
    '(//span[text()="Select document type"])[1]'
  end

  def american_or_alaskan_native_yes_radiobtn
    '//label[@for="indian_tribe_member_yes"]/span'
  end

  def american_or_alaskan_native_no_radiobtn
    '//label[@for="indian_tribe_member_no"]/span'
  end

  def incarcerated_yes_radiobtn
    '//label[@for="radio_incarcerated_yes"]/span'
  end

  def incarcerated_no_radiobtn
    '//label[@for="radio_incarcerated_no"]/span'
  end

  def address_line_one
    '//input[@id="person_addresses_attributes_0_address_1"]'
  end

  def address_line_two
    '//input[@id="person_addresses_attributes_0_address_2"]'
  end

  def city
    '//input[@id="person_addresses_attributes_0_city"]'
  end

  def select_state_dropdown
    '//span[text()="SELECT STATE *"]'
  end

  def zip
    '//input[@id="person_addresses_attributes_0_zip"]'
  end

  def homeless_dc_resident_checkbox
    '//input[@id="person_is_homeless"]'
  end

  def living_outside_dc_checkbox
    '//input[@id="person_is_temporarily_out_of_state"]'
  end

  def add_mailing_address_btn
    '//span[text()="Add Mailing Address"]'
  end

  def mailing_address_line_one
    '//input[@id="person_addresses_attributes_1_address_1"]'
  end

  def mailing_address_line_two
    '//input[@id="person_addresses_attributes_1_address_2"]'
  end

  def mailing_address_city
    '//input[@id="person_addresses_attributes_1_city"]'
  end

  def mailing_address_state_dropdown
    '//span[text()="SELECT STATE "]'
  end

  def mailing_address_zip
    '//input[@id="person_addresses_attributes_1_zip"]'
  end

  def remove_mailing_address_btn
    '//span[text()="Remove Mailing Address"]'
  end

  def home_phone
    '//input[@id="person_phones_attributes_0_full_phone_number"]'
  end

  def mobile_phone
    '//input[@id="person_phones_attributes_1_full_phone_number"]'
  end

  def personal_email_address
    '//input[@id="person_emails_attributes_0_address"]'
  end

  def work_email_address
    '//input[@id="person_emails_attributes_1_address"]'
  end

  def contact_method_dropdown
    '//span[text()="Both electronic and paper communications"]'
  end

  def language_preference_dropdown
    '//span[text()="English"]'
  end

  def help_me_sign_up_btn
    '//div[@class="btn btn-default btn-block help-me-sign-up"]'
  end
end


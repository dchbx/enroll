# frozen_string_literal: true

class PersonalInformation
  def self.tell_us_about_yourself_link
    find(:xpath, '//a[@class="interaction-click-control-tell-us-about-yourself"]')
  end

  def self.us_citizen_or_national_yes_radiobtn
    find(:xpath, '//label[@for="person_us_citizen_true"]/span')
  end

  def self.us_citizen_or_national_no_radiobtn
    find(:xpath, '//label[@for="person_us_citizen_false"]/span')
  end

  def self.naturalized_citizen_yes_radiobtn
    find(:xpath, '//label[@for="person_naturalized_citizen_true"]/span')
  end

  def self.naturalized_citizen_no_radiobtn
    find(:xpath, '//label[@for="person_naturalized_citizen_false"]/span')
  end

  def self.naturalized_citizen_not_sure_link
    find(:xpath, '(//div[@class="col-md-2 not-sure-margin left-seprator"])[1]//a')
  end

  def self.naturalized_citizen_select_doc_dropdown
    find(:xpath, '(//span[text()="Select document type"])[2]')
  end

  def self.immigration_status_yes_radiobtn
    find(:xpath, '//label[@for="person_eligible_immigration_status_true"]/span')
  end

  def self.immigration_status_no_radiobtn
    find(:xpath, '//label[@for="person_eligible_immigration_status_false"]/span')
  end

  def self.immigration_status_select_doc_dropdown
    find(:xpath, '(//span[text()="Select document type"])[1]')
  end

  def self.american_or_alaskan_native_yes_radiobtn
    find(:xpath, '//label[@for="indian_tribe_member_yes"]/span')
  end

  def self.american_or_alaskan_native_no_radiobtn
    find(:xpath, '//label[@for="indian_tribe_member_no"]/span')
  end

  def self.incarcerated_yes_radiobtn
    find(:xpath, '//label[@for="radio_incarcerated_yes"]/span')
  end

  def self.incarcerated_no_radiobtn
    find(:xpath, '//label[@for="radio_incarcerated_no"]/span')
  end

  def self.address_line_one
    find(:xpath, '//input[@id="person_addresses_attributes_0_address_1"]')
  end

  def self.address_line_two
    find(:xpath, '//input[@id="person_addresses_attributes_0_address_2"]')
  end

  def self.city
    find(:xpath, '//input[@id="person_addresses_attributes_0_city"]')
  end

  def self.select_state_dropdown
    find(:xpath, '//span[text()="SELECT STATE *"]')
  end

  def self.zip
    find(:xpath, '//input[@id="person_addresses_attributes_0_zip"]')
  end

  def self.homeless_dc_resident_checkbox
    find(:xpath, '//input[@id="person_is_homeless"]')
  end

  def self.living_outside_dc_checkbox
    find(:xpath, '//input[@id="person_is_temporarily_out_of_state"]')
  end

  def self.add_mailing_address_btn
    find(:xpath, '//span[text()="Add Mailing Address"]')
  end

  def self.mailing_address_line_one
    find(:xpath, '//input[@id="person_addresses_attributes_1_address_1"]')
  end

  def self.mailing_address_line_two
    find(:xpath, '//input[@id="person_addresses_attributes_1_address_2"]')
  end

  def self.mailing_address_city
    find(:xpath, '//input[@id="person_addresses_attributes_1_city"]')
  end

  def self.mailing_address_state_dropdown
    find(:xpath, '//span[text()="SELECT STATE "]')
  end

  def self.mailing_address_zip
    find(:xpath, '//input[@id="person_addresses_attributes_1_zip"]')
  end

  def self.remove_mailing_address_btn
    find(:xpath, '//span[text()="Remove Mailing Address"]')
  end

  def self.home_phone
    find(:xpath, '//input[@id="person_phones_attributes_0_full_phone_number"]')
  end

  def self.mobile_phone
    find(:xpath, '//input[@id="person_phones_attributes_1_full_phone_number"]')
  end

  def self.personal_email_address
    find(:xpath, '//input[@id="person_emails_attributes_0_address"]')
  end

  def self.work_email_address
    find(:xpath, '//input[@id="person_emails_attributes_1_address"]')
  end

  def self.contact_method_dropdown
    find(:xpath, '//span[text()="Both electronic and paper communications"]')
  end

  def self.language_preference_dropdown
    find(:xpath, '//span[text()="English"]')
  end

  def self.help_me_sign_up_btn
    find(:xpath, '//div[@class="btn btn-default btn-block help-me-sign-up"]')
  end
end


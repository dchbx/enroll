# frozen_string_literal: true

#insured/family_members?consumer_role_id
class IvlFamilyInformation

  def self.add_new_person
    '#household_info_add_member'
  end

  def self.continue_btn
    '#btn-continue, #btn_household_continue'
  end

  def self.edit_icon
    'i.fa-pencil-alt'
  end

  def self.dependent_first_name
    'dependent[first_name]'
  end

  def self.dependent_middle_name
    'dependent[middle_name]'
  end

  def self.dependent_last_name
    'dependent[last_name]'
  end

  def self.need_coverage_yes
    'label[for="is_applying_coverage_true"] span'
  end

  def self.need_coverage_no
    'label[for="is_applying_coverage_false"] span'
  end

  def self.not_sure_need_coverage_link
    'a[href="#is_applying_coverage"]'
  end

  def self.dependent_dob
    'jq_datepicker_ignore_dependent[dob]'
  end

  def self.dependent_ssn
    'dependent[ssn]'
  end

  def self.dependent_no_ssn_checkbox
    '#dependent_no_ssn'
  end

  def self.male_radiobtn
    'label[for="radio_male"] span'
  end

  def self.female_radiobtn
    'label[for="radio_female"] span'
  end

  def self.dependent_relationship_dropdown
    '.label'
  end

  def self.spouse
    'div.select-relation li[data-index="1"]'
  end

  def self.us_citizen_or_national_yes_radiobtn
    'label[for="dependent_us_citizen_true"] span'
  end

  def self.us_citizen_or_national_no_radiobtn
    'label[for="dependent_us_citizen_false"] span'
  end

  def self.not_sure_us_citizen_link
    'a[href="#us_citizen"]'
  end

  def self.naturalized_citizen_yes_radiobtn
    'label[for="dependent_naturalized_citizen_true"] span'
  end

  def self.naturalized_citizen_no_radiobtn
    'label[for="dependent_naturalized_citizen_false"] span'
  end

  def self.not_sure_naturalized_citizen
    'a[href="#naturalized_citizen"]'
  end

  def self.naturalized_citizen_select_doc_dropdown
    '#naturalization_doc_type_select span'
  end

  def self.immigration_status_yes_radiobtn
    'label[for="dependent_eligible_immigration_status_true"] span'
  end

  def self.immigration_status_no_radiobtn
    'label[for="dependent_eligible_immigration_status_false"] span'
  end

  def self.immigration_status_select_doc_dropdown
    '#immigration_doc_type_select span'
  end

  def self.american_or_alaskan_native_yes_radiobtn
    'label[for="indian_tribe_member_yes"] span'
  end

  def self.american_or_alaskan_native_no_radiobtn
    'label[for="indian_tribe_member_no"] span'
  end

  def self.tribal_id
    'dependent[tribal_id]'
  end

  def self.incarcerated_yes_radiobtn
    'label[for="radio_incarcerated_yes"] span'
  end

  def self.incarcerated_no_radiobtn
    'label[for="radio_incarcerated_no"] span'
  end

  def self.not_sure_incarcerated_link
    'a[href="#is_incarcerated"]'
  end

  def self.white_checkbox
    '#dependent_ethnicity_white'
  end

  def self.black_or_african_american_checkbox
    '#dependent_ethnicity_black_or_african_american'
  end

  def self.asian_indian_checkbox
    '#dependent_ethnicity_asian_indian'
  end

  def self.chinese_checkbox
    '#dependent_ethnicity_chinese'
  end

  def self.filipino_checkbox
    '#dependent_ethnicity_filipino'
  end

  def self.japanese_checkbox
    '#dependent_ethnicity_japanese'
  end

  def self.korean_checkbox
    '#dependent_ethnicity_korean'
  end

  def self.vietnamese_checkbox
    '#dependent_ethnicity_vietnamese'
  end

  def self.other_asian_checkbox
    '#dependent_ethnicity_other_asian'
  end

  def self.native_hawaiian_checkbox
    '#dependent_ethnicity_native_hawaiian'
  end

  def self.samoan_checkbox
    '#dependent_ethnicity_samoan'
  end

  def self.guamanian_or_chamorro_checkbox
    '#dependent_ethnicity_guamanian_or_chamorro'
  end

  def self.other_pacific_islander_checkbox
    '#dependent_ethnicity_other_pacific_islander'
  end

  def self.american_indian_checkbox
    '#dependent_ethnicity_american_indianalaska_native'
  end

  def self.other_race_checkbox
    '#dependent_ethnicity_other'
  end

  def self.lives_with_prim_subs_checkbox
    'input[id="dependent_same_with_primary"]'
  end

  def self.address_line_one
    'dependent[addresses][0][address_1]'
  end

  def self.address_line_two
    'dependent[addresses][0][address_2]'
  end

  def self.city
    'dependent[addresses][0][city]'
  end

  def self.select_state_dropdown
    'div.home-div span.label'
  end

  def self.zip
    'dependent[addresses][0][zip]'
  end

  def self.living_outside_dc_checkbox
    '#dependent_is_temporarily_out_of_state'
  end

  def self.homeless_checkbox
    '#dependent_is_homeless'
  end

  def self.confirm_member_btn
    '#add_info_buttons_ span'
  end

  def self.cancel_btn
    '#add_info_buttons_ a'
  end

  def self.previous_link
    'a.interaction-click-control-previous'
  end

  def self.save_and_exit_link
    'a.interaction-click-control-save---exit'
  end

  def self.help_me_sign_up_btn
    '.help-me-sign-up'
  end
end
module Insured::FamilyMembersHelper
  def employee_dependent_form_id(model)
    if model.try(:persisted?)
      "add_member_list_#{model.id}"
    else
      "new_employee_dependent_form"
    end
  end

  def employee_dependent_submission_options_for(model)
    if model.try(:persisted?)
      { :remote => true, method: :put, :url => insured_family_member_path(id: model.id), :as => :dependent }
    else
      { :remote => true, method: :post, :url => insured_family_members_path, :as => :dependent }
    end
  end

  def get_address_from_dependent(dependent)
    if dependent.class == FamilyMember
      dependent.person.addresses
    else
      dependent.family_member.person.addresses
    end
  rescue
    []
  end

  # Returns [url, disable_flag]
  def build_button consumer_role, family, find_sep_url, missing_relationships=nil
    if missing_relationships.present?
      [insured_family_relationships_path(:consumer_role_id => consumer_role.id), false]
    else
      if family.application_in_progress.present?
        if family.application_in_progress.incomplete_applicants?
          [go_to_step_financial_assistance_application_applicant_path(family.application_in_progress, family.application_in_progress.next_incomplete_applicant, 1), !family.application_in_progress.ready_for_attestation?]
        else
          [review_and_submit_financial_assistance_application_path(family.application_in_progress), !family.application_in_progress.ready_for_attestation?]
        end
      else
        [(consumer_role.present? && !is_under_open_enrollment? ? find_sep_url : group_selection_url), false]
      end
    end
  end

  def is_applying_coverage_value_dependent(dependent)
    first_checked = true
    second_checked = false
    if dependent.family_member.try(:person).try(:consumer_role).present?
      first_checked = dependent.family_member.person.consumer_role.is_applying_coverage
      second_checked = !dependent.family_member.person.consumer_role.is_applying_coverage
    end
    return first_checked, second_checked
  end
end

module Parser
  class PlanCrossWalkParser
    include HappyMapper

    tag 'crosswalk'

    element :plan_id_2017_hios, String, tag: "plan_id_2017_hios"
    element :crosswalk_level, String, tag: "crosswalk_level"
    element :reason_for_crosswalk, String, tag: "reason_for_crosswalk"
    element :plan_id_2018_hios, String, tag: "plan_id_2018_hios"
    element :plan_id_2019_hios, String, tag: "plan_id_2019_hios"
    element :plan_id_2020_hios, String, tag: "plan_id_2020_hios"
    element :is_this_plan_catastrophic_or_child_only_plan, String, tag: "is_this_plan_catastrophic_or_child_only_plan"
    element :plan_id_2018_for_enrollees_aging_off_catastrophic_or_child_only_plan, String, tag: "plan_id_2018_for_enrollees_aging_off_catastrophic_or_child_only_plan"
    element :plan_id_2019_for_enrollees_aging_off_catastrophic_or_child_only_plan, String, tag: "plan_id_2019_for_enrollees_aging_off_catastrophic_or_child_only_plan"
    element :plan_id_2020_for_enrollees_aging_off_catastrophic_or_child_only_plan, String, tag: "plan_id_2020_for_enrollees_aging_off_catastrophic_or_child_only_plan"
    element :are_you_prohibited_from_selling_or_issuing_the_2018_qhp_to_someone_enrolled_in_medicare_as_set_forth_in_section_1882d_of_the_social_security_act, String, tag: "Are_you_prohibited_from_selling_or_issuing_the_2018_QHP_to_someone_enrolled_in_Medicare_as_set_forth_in_Section_1882d_of_the_Social_Security_Act"
    # element :Does_re-enrollment_in_the_2018_QHP_represent_an_enrollment_into_a_new_policy_or_contract_under_state_law_for_enrollees_in_the_2017_QHP, String, tag: "Does_re-enrollment_in_the_2018_QHP_represent_an_enrollment_into_a_new_policy_or_contract_under_state_law_for_enrollees_in_the_2017_QHP"

   def to_hash
      {
        plan_id_2017_hios: plan_id_2017_hios.present? ? plan_id_2017_hios.gsub(/\n/,'').strip : "",
        crosswalk_level: crosswalk_level.present? ? crosswalk_level.gsub(/\n/,'').strip : "",
        reason_for_crosswalk: (reason_for_crosswalk.gsub(/\n/,'').strip rescue ""),
        plan_id_2018_hios: plan_id_2018_hios.present? ? plan_id_2018_hios.gsub(/\n/,'').strip : "",
        plan_id_2019_hios: plan_id_2019_hios.present? ? plan_id_2019_hios.gsub(/\n/,'').strip : "",
        plan_id_2020_hios: plan_id_2020_hios.present? ? plan_id_2020_hios.gsub(/\n/,'').strip : "",
        is_this_plan_catastrophic_or_child_only_plan: is_this_plan_catastrophic_or_child_only_plan.gsub(/\n/,'').strip,
        plan_id_2018_for_enrollees_aging_off_catastrophic_or_child_only_plan: plan_id_2018_for_enrollees_aging_off_catastrophic_or_child_only_plan.present? ? plan_id_2018_for_enrollees_aging_off_catastrophic_or_child_only_plan.gsub(/\n/,'').strip : "",
        plan_id_2019_for_enrollees_aging_off_catastrophic_or_child_only_plan: plan_id_2019_for_enrollees_aging_off_catastrophic_or_child_only_plan.present? ? plan_id_2019_for_enrollees_aging_off_catastrophic_or_child_only_plan.gsub(/\n/,'').strip : "",
        plan_id_2020_for_enrollees_aging_off_catastrophic_or_child_only_plan: plan_id_2020_for_enrollees_aging_off_catastrophic_or_child_only_plan.present? ? plan_id_2020_for_enrollees_aging_off_catastrophic_or_child_only_plan.gsub(/\n/,'').strip : "",
        are_you_prohibited_from_selling_or_issuing_the_2018_qhp_to_someone_enrolled_in_medicare_as_set_forth_in_section_1882d_of_the_social_security_act: are_you_prohibited_from_selling_or_issuing_the_2018_qhp_to_someone_enrolled_in_medicare_as_set_forth_in_section_1882d_of_the_social_security_act.present? ? are_you_prohibited_from_selling_or_issuing_the_2018_qhp_to_someone_enrolled_in_medicare_as_set_forth_in_section_1882d_of_the_social_security_act.gsub(/\n/,'').strip : "",
        # "Does_re-enrollment_in_the_2018_QHP_represent_an_enrollment_into_a_new_policy_or_contract_under_state_law_for_enrollees_in_the_2017_QHP" => "Does_re-enrollment_in_the_2018_QHP_represent_an_enrollment_into_a_new_policy_or_contract_under_state_law_for_enrollees_in_the_2017_QHP".gsub(/\n/,'').strip,
      }
    end
  end
end

glue_report_filename = ''

enrollment_ids = []

enrolled_status = %w(coverage_selected transmitted_to_carrier coverage_enrolled coverage_termination_pending enrolled_contingent unverified)

terminated_status = %w(coverage_terminated unverified coverage_expired void)

canceled_status = %w(coverage_canceled)

renewal_status = %w(auto_renewing renewing_coverage_selected renewing_transmitted_to_carrier renewing_coverage_enrolled auto_renewing_contingent renewing_contingent_selected 
                    renewing_contingent_transmitted_to_carrier renewing_contingent_enrolled)

enroll_rows = []

CSV.foreach(glue_report_filename, headers: true) do |row|
  health_enrollment = HbxEnrollment.by_hbx_id(row["health_policy.eg_id"]).first
  row["health.exists.in.enroll"] = health_enrollment.present?
  if health_enrollment.present?
    plan = health_enrollment.plan
    row["enroll.health_policy.plan.name"] = plan.name
    row["enroll.health_policy.plan.coverage_type"] = plan.coverage_kind
    row["enroll.health_policy.plan.metal_level"] = plan.metal_level
    row["enroll.health_policy.applied_aptc"] = health_enrollment.applied_aptc_amount.to_s
    health_subscriber_person = health_enrollment.subscriber.person
    row["enroll.health.subscriber.hbx_id"] = health_subscriber_person.hbx_id
    row["enroll.health.subscriber.name_full"] = health_subscriber_person.full_name
  else
    row["enroll.health_policy.plan.name"] = ""
    row["enroll.health_policy.plan.coverage_type"] = ""
    row["enroll.health_policy.plan.metal_level"] = ""
    row["enroll.health_policy.applied_aptc"] = ""
    row["enroll.health.subscriber.hbx_id"] = ""
    row["enroll.health.subscriber.name_full"] = ""   
  end
  unless row["dental_policy.eg_id"].blank?
    dental_enrollment = HbxEnrollment.by_hbx_id(row["dental_policy.eg_id"]).first
    row["dental.exists.in.enroll"] = dental_enrollment.present?
    if dental_enrollment.present?
      plan = dental_enrollment.plan
      row["enroll.dental_policy.plan.name"] = plan.name
      row["enroll.dental_policy.plan.coverage_type"] = plan.coverage_kind
      row["enroll.dental_policy.plan.metal_level"] = plan.metal_level
      row["enroll.dental_policy.applied_aptc"] = dental_enrollment.applied_aptc_amount.to_s
      dental_subscriber_person = dental_enrollment.subscriber.person
      row["enroll.dental.subscriber.hbx_id"] = dental_subscriber_person.hbx_id
      row["enroll.dental.subscriber.name_full"] = dental_subscriber_person.full_name
    else
      row["enroll.dental_policy.plan.name"] = ""
      row["enroll.dental_policy.plan.coverage_type"] = ""
      row["enroll.dental_policy.plan.metal_level"] = ""
      row["enroll.dental_policy.applied_aptc"] = ""
      row["enroll.dental.subscriber.hbx_id"] = ""
      row["enroll.dental.subscriber.name_full"] = ""      
    end
  end
  enroll_rows << row
end

enroll_report_filename = "#{glue_report_filename.gsub(".csv","")}_enroll.csv"

CSV.open(enroll_report_filename, "w") do |csv|
  csv << %w(health_policy.eg_id health_policy.plan.name health_policy.pre_amt_tot health_policy.applied_aptc health_policy.policy_start health_policy.aasm_state 
            health_policy.plan.coverage_type health_policy.plan.metal_level 
            dental_policy.eg_id dental_policy.plan.name dental_policy.pre_amt_tot dental_policy.applied_aptc dental_policy.policy_start dental_policy.aasm_state 
            dental_policy.plan.coverage_type dental_policy.plan.metal_level 
            person.authority_member_id person.name_full person.mailing_address is_dependent is_responsible_party?
            health.exists.in.enroll 
            enroll.health_policy.plan.name 
            enroll.health_policy.plan.coverage_type 
            enroll.health_policy.plan.metal_level
            enroll.health_policy.applied_aptc 
            enroll.health.subscriber.hbx_id 
            enroll.health.subscriber.name_full
            dental.exists.in.enroll 
            enroll.dental_policy.plan.name 
            enroll.dental_policy.plan.coverage_type 
            enroll.dental_policy.plan.metal_level
            enroll.dental_policy.applied_aptc 
            enroll.dental.subscriber.hbx_id 
            enroll.dental.subscriber.name_full)
  enroll_rows.each do |row|
    csv << row
  end
end


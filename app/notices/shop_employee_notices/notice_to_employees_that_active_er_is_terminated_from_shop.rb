class ShopEmployeeNotices::NoticeToEmployeesThatActiveErIsTerminatedFromShop < ShopEmployeeNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
    send_generic_notice_alert_to_employer
  end

  def send_generic_notice_alert_to_employer
    name = census_employee.employer_profile.staff_roles.first.full_name
    to = census_employee.employer_profile.staff_roles.first.work_email_or_best
    UserMailer.generic_notice_alert(name,subject,to).deliver_now
  end

  def append_data
    plan_year = census_employee.employer_profile.plan_years.where(:aasm_state => "terminated").sort_by(&:updated_at).last
    notice.primary_email = census_employee.employee_role.person.work_email_or_best
    group_lost_on = plan_year.terminated_on+60.days
    notice.plan_year = PdfTemplates::PlanYear.new({
                                                      :terminated_on => plan_year.terminated_on,
                                                      :group_lost_on => group_lost_on
                                                  })
  end
end
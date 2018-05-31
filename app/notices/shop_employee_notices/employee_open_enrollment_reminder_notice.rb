class ShopEmployeeNotices::EmployeeOpenEnrollmentReminderNotice < ShopEmployeeNotice

  attr_accessor :census_employee

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    employer = census_employee.employer_profile
    if employer.is_new_employer?
      plan_year = census_employee.active_benefit_group_assignment.benefit_group.plan_year
    elsif employer.is_renewing_employer?
      plan_year = census_employee.renewal_benefit_group_assignment.benefit_group.plan_year
    end
    notice.plan_year = PdfTemplates::PlanYear.new({
                      :open_enrollment_end_on => plan_year.open_enrollment_end_on
      })
  end

end
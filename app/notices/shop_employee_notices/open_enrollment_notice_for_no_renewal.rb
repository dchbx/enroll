class ShopEmployeeNotices::OpenEnrollmentNoticeForNoRenewal < ShopEmployeeNotice

  attr_accessor :census_employee

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    renewing_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING).first
    notice.plan_year = PdfTemplates::PlanYear.new({
      :start_on => renewing_plan_year.start_on,
      :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on
      })
    enrollment = census_employee.active_benefit_group_assignment.hbx_enrollments.first
    notice.plan = PdfTemplates::Plan.new({
      :plan_name => enrollment.plan.name
      })
  end

end
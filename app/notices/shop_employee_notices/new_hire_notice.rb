class ShopEmployeeNotices::NewHireNotice < ShopEmployeeNotice

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
    plan_year = census_employee.employer_profile.plan_years.last
    notice.plan_year = PdfTemplates::PlanYear.new({
      :start_on => plan_year.start_on,
      :open_enrollment_end_on => plan_year.open_enrollment_end_on
      })
    notice.hired_on = census_employee.hired_on
  end

end
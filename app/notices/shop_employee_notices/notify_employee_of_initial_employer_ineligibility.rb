class ShopEmployeeNotices::NotifyEmployeeOfInitialEmployerIneligibility < ShopEmployeeNotice

  attr_accessor :census_employee

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    plan_year = census_employee.employer_profile.plan_years.where(aasm_state: 'application_ineligible').last
    notice.plan_year = PdfTemplates::PlanYear.new({
                      :start_on => plan_year.start_on
      })
  end

end

class ShopEmployeeNotices::TerminationOfEmployersHealthCoverage < ShopEmployeeNotice

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
    active_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::INITIAL_ELIGIBLE_STATE).first
    notice.plan_year = PdfTemplates::PlanYear.new({
                      :start_on => active_plan_year.start_on
      })
  end
end

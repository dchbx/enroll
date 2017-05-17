class ShopEmployerNotices::InitialEmployerOpenEnrollmentBegin < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    plan_year = employer_profile.plan_years.where(:aasm_state.in => PlanYear::INITIAL_ELIGIBLE_STATE).first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :open_enrollment_start_on => plan_year.open_enrollment_start_on,
          :open_enrollment_end_on => plan_year.open_enrollment_end_on
        })
    notice.plan_year.binder_payment_due_date = PlanYear.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
  end
end
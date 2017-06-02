class ShopEmployerNotices::InitialEmployerReminderToPublishPlanYear < ShopEmployerNotice

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
    plan_year = employer_profile.plan_years.where(:aasm_state => "draft").first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :start_on => plan_year.start_on,
        })
    notice.plan_year.binder_payment_due_date = PlanYear.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
  end
end
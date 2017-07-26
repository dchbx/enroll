class ShopEmployerNotices::LowEnrollmentNotice < ShopEmployerNotice

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
    plan_year = employer_profile.plan_years.where(:aasm_state.in => ["enrolling", "renewing_enrolling"]).first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :open_enrollment_end_on => plan_year.open_enrollment_end_on,
          :total_enrolled_count => plan_year.total_enrolled_count,
          :eligible_to_enroll_count => plan_year.eligible_to_enroll_count
        })

    #binder payment deadline
    notice.plan_year.binder_payment_due_date = PlanYear.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_non_discrimination_attachment.pdf')]
  end

end
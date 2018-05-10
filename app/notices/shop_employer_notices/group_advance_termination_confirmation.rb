class ShopEmployerNotices::GroupAdvanceTerminationConfirmation < ShopEmployerNotice

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
    plan_year = employer_profile.plan_years.first
    notice.plan_year = PdfTemplates::PlanYear.new({ end_on: plan_year.end_on })
  end

end

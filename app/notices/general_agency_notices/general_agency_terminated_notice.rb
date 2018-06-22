class GeneralAgencyNotices::GeneralAgencyTerminatedNotice < GeneralAgencyNotice

  def deliver
    build
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end
end

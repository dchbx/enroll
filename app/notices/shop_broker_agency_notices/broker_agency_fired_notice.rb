class ShopBrokerAgencyNotices::BrokerAgencyFiredNotice < ShopBrokerAgencyNotice

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
    notice.assignment_end_date = employer_profile.broker_agency_accounts.unscoped.last.end_on 
  end

end
class IvlNotices::NoAppealVariableIvlRenewalNotice < IvlNotices::VariableIvlRenewalNotice

  def deliver
    build
    generate_pdf_notice
    prepend_envelope
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

end
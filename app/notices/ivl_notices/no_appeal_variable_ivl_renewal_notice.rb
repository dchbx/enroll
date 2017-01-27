class IvlNotices::NoAppealVariableIvlRenewalNotice < IvlNotices::VariableIvlRenewalNotice

  def append_enrollments(eg_ids)
    enrollments_for_notice = []
    eg_ids.each do |eg_id|
      enrollments_for_notice << HbxEnrollment.by_hbx_id(eg_id).first
    end
    enrollments_for_notice.each do |hbx_enrollment|
      @notice.enrollments << build_enrollment(hbx_enrollment)
    end
  end

  def build
    append_enrollments(enrollment_group_ids)
    notice.primary_fullname = recipient.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present'
    end
  end

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
class ShopEmployeeNotices::EmployeeEligibilityNotice < ShopEmployeeNotice

  attr_accessor :census_employee

  def deliver
    build
    generate_pdf_notice
    employee_appeal_rights_attachment
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

end
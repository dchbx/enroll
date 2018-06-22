class ShopEmployerNotices::EmployerInvoiceAvailable < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    # send_generic_notice_alert_to_broker_and_ga  # turning off emails to brokers/GA
  end
  def append_data
    plan_year = employer_profile.plan_years.where(:aasm_state.in => PlanYear::PUBLISHED + ["terminated"]).first
    notice.plan_year = PdfTemplates::PlanYear.new({
                                                      :start_on => plan_year.start_on,
                                                  })
    notice.plan_year.binder_payment_due_date = PlanYear.calculate_open_enrollment_date(plan_year.start_on)[:binder_payment_due_date]
  end

  def create_secure_inbox_message(notice)
    body = "<br>Your invoice is now available in your employer profile under the Billing tab. For more information, please download your " +
            "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s, 
              recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
    message = recipient.inbox.messages.build({ subject: subject, body: body, from: 'DC Health Link' })
    message.save!
  end

end
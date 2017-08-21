class ShopEmployerNotices::EmployerRenewalNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice

    if employer_profile.is_converting?
      conversion_attachment
    end
    
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
  end

  def create_secure_inbox_message(notice)
    if (key.present? && key.downcase == "corrected")
      body = "This notice is a corrected version of the original 'Group Renewal Available' notice you previously received. The original notice listed two different open enrollment end dates.
              This notice confirms your latest possible open enrollment end date is the 13th of the month prior to your plan year start date. Please contact #{Settings.site.short_name}'s call center at #{Settings.contact_center.phone_number} [TTY: 711] with any questions.<br></br>You can download the notice by clicking this link " +
              "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
                recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
      subject = "CORRECTED: Open Enrollment End Date - Group Renewal Available"
    else
      body = "<br>You can download the notice by clicking this link " +
              "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s,
                recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
      subject = notice.title
    end
    message = recipient.inbox.messages.build({ subject: subject, body: body, from: "#{Settings.site.short_name}" })
    message.save!
  end

  def append_data
    renewing_plan_year = employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING).first
    notice.plan_year = PdfTemplates::PlanYear.new({
          :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on,
          :start_on => renewing_plan_year.start_on,
          :carrier_name => renewing_plan_year.benefit_groups.first.reference_plan.carrier_profile.legal_name
        })
  end

  def conversion_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'conversion_employer_attachment.pdf')]
  end

end
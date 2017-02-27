class ShopNotices::RenewalGroupNotice < ShopNotices::EmployerRenewalNotice

  def deliver
    build
    append_data
    super
  end

  def append_data
    renewing_plan_year = employer_profile.plan_years.where(:aasm_state => "renewing_draft").first
    notice.plan = PdfTemplates::Plan.new({
          :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on,
          :coverage_start_on => renewing_plan_year.start_on
        })
  end

  def create_secure_inbox_message(notice)
    body = "<br>You can download the notice by clicking this link " +
            "<a href=" + "#{Rails.application.routes.url_helpers.authorized_document_download_path(recipient.class.to_s, 
              recipient.id, 'documents', notice.id )}?content_type=#{notice.format}&filename=#{notice.title.gsub(/[^0-9a-z]/i,'')}.pdf&disposition=inline" + " target='_blank'>" + notice.title + "</a>"
    message = recipient.inbox.messages.build({ subject: subject, body: body, from: 'DC Health Link' })
    message.save!
  end
end
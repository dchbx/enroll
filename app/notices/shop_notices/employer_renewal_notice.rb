class ShopNotices::EmployerRenewalNotice < ShopNotice

  def deliver
    build
    append_data
    generate_pdf_notice

    if employer_profile.is_conversion?
      conversion_attachment
    end
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    renewing_plan_year = employer_profile.plan_years.where(:aasm_state => "renewing_draft").first
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
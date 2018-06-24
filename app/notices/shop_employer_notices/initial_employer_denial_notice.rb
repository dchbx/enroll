class ShopEmployerNotices::InitialEmployerDenialNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
  end

  def append_data
    plan_year = employer_profile.plan_years.where(aasm_state: 'publish_pending').last
    plan_year_warnings = []
    plan_year.application_eligibility_warnings.each do |k, v|
      case k.to_s
      when "fte_count"
        plan_year_warnings << "Full Time Equivalent must be 1-50"
      when "primary_office_location"
        plan_year_warnings << "primary business address not located in the District of Columbia"
      end
    end
    notice.plan_year = PdfTemplates::PlanYear.new({
          :warnings => plan_year_warnings,
        })
  end

end
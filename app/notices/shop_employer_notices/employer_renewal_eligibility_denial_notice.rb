class ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    shop_dchl_rights_attachment
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    active_plan_year = employer_profile.plan_years.where(:aasm_state => "active").first
    renewing_plan_year = employer_profile.plan_years.where(:aasm_state => "renewing_publish_pending").first
    plan_year_warnings = []
    if renewing_plan_year.application_eligibility_warnings.include?(:primary_office_location)
      plan_year_warnings << "primary location is outside washington dc"
    end
    notice.plan_year = PdfTemplates::PlanYear.new({
          :end_on => active_plan_year.end_on,
          :start_on => renewing_plan_year.start_on,
          :warnings => plan_year_warnings
        })
  end
end

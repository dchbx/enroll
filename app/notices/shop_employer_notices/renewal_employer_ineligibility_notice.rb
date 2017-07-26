class ShopEmployerNotices::RenewalEmployerIneligibilityNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    shop_dchl_rights_attachment
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
  end

  def append_data
    renewing_plan_year = employer_profile.plan_years.where(:aasm_state => "renewing_application_ineligible").first
    active_plan_year = employer_profile.plan_years.where(:aasm_state => "active").first

    plan_year_warnings = []
    renewing_plan_year.enrollment_errors.each do |k, v|
      case k.to_s
      when "enrollment_ratio"
        plan_year_warnings << "At least two-thirds of your eligible employees enrolled in your group health coverage or waive due to having other coverage."
      when "non_business_owner_enrollment_count"
        plan_year_warnings << "One non-owner employee enrolled in health coverage"
      end
    end

    notice.plan_year = PdfTemplates::PlanYear.new({
        :start_on => renewing_plan_year.start_on,
        :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on,
        :end_on => active_plan_year.end_on,
        :warnings => plan_year_warnings
      })
  end

end

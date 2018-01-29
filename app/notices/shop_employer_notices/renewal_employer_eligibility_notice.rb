class ShopEmployerNotices::RenewalEmployerEligibilityNotice < ShopEmployerNotice

  attr_accessor :employer_profile

  def deliver
    build
    build_plan_year
    generate_pdf_notice
    shop_dchl_rights_attachment
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
    send_generic_notice_alert_to_broker_and_ga
  end

  def build_plan_year
    active_plan_year = employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE).first
    notice.plan_year = PdfTemplates::PlanYear.new({
        :open_enrollment_start_on => active_plan_year.open_enrollment_start_on,
        :open_enrollment_end_on => active_plan_year.open_enrollment_end_on
      })
  end

end 

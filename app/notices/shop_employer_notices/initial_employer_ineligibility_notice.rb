class ShopEmployerNotices::InitialEmployerIneligibilityNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    employer_appeal_rights_attachment
    attach_envelope
    non_discrimination_attachment
    shop_dchl_rights_attachment
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    initial_plan_year = employer_profile.plan_years.where(:aasm_state => "application_ineligible").first
    active_plan_year = employer_profile.plan_years.where(:aasm_state => "active").first
    plan_year = employer_profile.plan_years.first

    plan_year_warnings = []
    if plan_year
      if plan_year.enrollment_errors.key?(:enrollment_ratio)
        plan_year_warnings << "At least 75% of your eligible employees enrolled in your group health coverage or waive due to having other coverage."
      end
      plan_year_warnings << "One non-owner employee enrolled in health coverage" if plan_year.enrollment_errors.key?(:non_business_owner_enrollment_count)
    end

    notice.plan_year = PdfTemplates::PlanYear.new({
        :start_on => plan_year.start_on,
        :open_enrollment_end_on => plan_year.open_enrollment_end_on,
        :end_on => plan_year.end_on,
        :warnings => plan_year_warnings
      })
  end

end

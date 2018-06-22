class ShopEmployerNotices::InitialEmployerIneligibilityNotice < ShopEmployerNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    shop_dchl_rights_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    plan_year = employer_profile.plan_years.where(:aasm_state => "application_ineligible").first

    plan_year_warnings = []
    plan_year.enrollment_errors.each do |k, v|
      case k.to_s
      when "enrollment_ratio"
        plan_year_warnings << "At least two-thirds of your eligible employees enrolled in your group health coverage or waive due to having other coverage."
      when "non_business_owner_enrollment_count"
        plan_year_warnings << "One non-owner employee enrolled in health coverage"
      end
    end
    notice.plan_year = PdfTemplates::PlanYear.new({
          :start_on => plan_year.start_on,
          :open_enrollment_end_on => plan_year.open_enrollment_end_on,
          :warnings => plan_year_warnings
        })
  end

end
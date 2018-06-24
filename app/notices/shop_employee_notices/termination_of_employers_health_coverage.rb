class ShopEmployeeNotices::TerminationOfEmployersHealthCoverage < ShopEmployeeNotice

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    active_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::INITIAL_ELIGIBLE_STATE).first
    notice.plan_year = PdfTemplates::PlanYear.new({
                      :start_on => active_plan_year.start_on
      })

    ben_sponsorship = HbxProfile.current_hbx.benefit_sponsorship
    current_open_enrollment_coverage = ben_sponsorship.benefit_coverage_periods.where(open_enrollment_end_on: Settings.aca.individual_market.open_enrollment.end_on ).first
    bc_period = current_open_enrollment_coverage.open_enrollment_end_on >= TimeKeeper.date_of_record ? current_open_enrollment_coverage : ben_sponsorship.renewal_benefit_coverage_period

    notice.enrollment = PdfTemplates::Enrollment.new({
              :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
              :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
              })
  end
end
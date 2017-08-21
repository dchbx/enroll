class ShopEmployeeNotices::SepRequestDenialNotice < ShopEmployeeNotice

  attr_accessor :census_employee

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
    sep = census_employee.employee_role.person.primary_family.special_enrollment_periods.order_by(:"created_at".desc)[0]
    notice.sep = PdfTemplates::SpecialEnrollmentPeriod.new({
      :qle_on => sep.qle_on,
      :end_on => sep.end_on,
      :title => sep.title
      })

    active_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::PUBLISHED || PlanYear::RENEWING).first
    renewing_plan_year_start_on = active_plan_year.end_on+1
    notice.plan_year = PdfTemplates::PlanYear.new({
      :open_enrollment_end_on => active_plan_year.open_enrollment_end_on,
      :start_on => renewing_plan_year_start_on
      })

    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
    notice.enrollment = PdfTemplates::Enrollment.new({
              :effective_on => bc_period.start_on,
              :plan_year => bc_period.start_on.year,
              :ivl_open_enrollment_start_on => bc_period.open_enrollment_start_on,
              :ivl_open_enrollment_end_on => bc_period.open_enrollment_end_on
              })
  end
end

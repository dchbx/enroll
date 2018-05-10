class ShopEmployeeNotices::EmployeeSelectPlanDuringOpenEnrollment < ShopEmployeeNotice
 
  def initialize(census_employee, args)
    @enrollment_id = args[:options][:enrollment_hbx_id]
    super(census_employee, args)
  end

  def deliver
    build
    append_data
    generate_pdf_notice
    attach_envelope
    non_discrimination_attachment
    upload_and_send_secure_message
    send_generic_notice_alert 
  end

  def append_data
    plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::INITIAL_ELIGIBLE_STATE).first
    notice.plan_year = PdfTemplates::PlanYear.new({
        :open_enrollment_start_on => plan_year.open_enrollment_start_on,
        :open_enrollment_end_on => plan_year.open_enrollment_end_on,
        :start_on => plan_year.start_on
        })

    enrollment = HbxEnrollment.by_hbx_id(@enrollment_id).first
    plan = enrollment.plan
    notice.plan = PdfTemplates::Plan.new({
        :plan_name => plan.try(:name)
        })
    notice.enrollment = PdfTemplates::Enrollment.new({
        :effective_on => enrollment.effective_on,
        :responsible_amount => enrollment.total_employer_contribution,
        :employee_cost => enrollment.total_employee_cost,
        })
  end
end 
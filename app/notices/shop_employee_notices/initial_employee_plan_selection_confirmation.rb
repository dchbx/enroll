class ShopEmployeeNotices::InitialEmployeePlanSelectionConfirmation < ShopEmployeeNotice

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
    plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => ["enrolled", "enrolling"]).first
    notice.plan_year = PdfTemplates::PlanYear.new({
      :start_on => plan_year.start_on
      })
    health_enrs, dental_enrs = census_employee.active_benefit_group_assignment.hbx_enrollments.partition{|enr| enr.coverage_kind == "health"}

    enrollment = health_enrs.first
    
    if enrollment.present?
      notice.enrollment = PdfTemplates::Enrollment.new({ 
        responsible_amount: enrollment.total_employer_contribution,
        employee_cost: enrollment.total_employee_cost,
        })
      plan = enrollment.plan
      notice.plan = PdfTemplates::Plan.new({
        :plan_name => plan.name
      })
    end

    dental_enrollment = dental_enrs.first
    
    if dental_enrollment.present?
      notice.dental_enrollment = PdfTemplates::Enrollment.new({ 
        responsible_amount: dental_enrollment.total_employer_contribution,
        employee_cost: dental_enrollment.total_employee_cost,
        })
      dental_plan = dental_enrollment.plan
      notice.dental_plan = PdfTemplates::Plan.new({
        :plan_name => dental_plan.name
      })
    end
  end
end